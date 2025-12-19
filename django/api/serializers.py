from rest_framework import serializers
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from datetime import timedelta
from django.utils import timezone
from django.db.models import Q, Count
from .models import UserProfile, Friendship, Ping, CheckInSession

User = get_user_model()

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ['status', 'fcm_token']

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['username', 'email', 'password']

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password']
        )
        return user

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        # Add extra responses to the login response
        data.update({'username': self.user.username})
        data.update({'email': self.user.email})
        if hasattr(self.user, 'profile'):
            data.update({'status': self.user.profile.status})
            data.update({'fcm_token': self.user.profile.fcm_token})
        return data

class FriendRequestSerializer(serializers.Serializer):
    receiver_id = serializers.IntegerField()

    def validate_receiver_id(self, value):
        if not User.objects.filter(id=value).exists():
            raise serializers.ValidationError("User not found.")
        return value

    def validate(self, data):
        request = self.context.get('request')
        sender = request.user
        receiver_id = data['receiver_id']
        
        if sender.id == receiver_id:
            raise serializers.ValidationError("You cannot add yourself as a friend.")

        # Check existing friendship
        if Friendship.objects.filter(
            Q(sender=sender, receiver_id=receiver_id) | 
            Q(sender_id=receiver_id, receiver=sender)
        ).exists():
            raise serializers.ValidationError("Friendship already exists or is pending.")
        
        return data

class FriendshipActionSerializer(serializers.Serializer):
    action = serializers.ChoiceField(choices=['accept', 'decline'])

class VIPSerializer(serializers.Serializer):
    is_vip = serializers.BooleanField()

class PingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ping
        fields = ['id', 'receiver', 'ping_type', 'message', 'status', 'created_at', 'delivered_at', 
                  'latitude', 'longitude', 'audio_file', 'battery_level', 'response_message', 'response_at']
        read_only_fields = ['status', 'created_at', 'delivered_at', 'response_message', 'response_at']

    def validate(self, attrs):
        request = self.context['request']
        sender = request.user
        receiver = attrs['receiver']
        
        # 1. Friendship Check
        friendship = Friendship.objects.filter(
            (Q(sender=sender, receiver=receiver) | Q(sender=receiver, receiver=sender)) &
            Q(status='accepted')
        ).first()

        if not friendship:
            raise serializers.ValidationError("You can only ping accepted friends.")
        
        # 2. VIP Check (Only if ping_type is 'emergency' or 'battery')
        if attrs.get('ping_type') in ['emergency', 'battery']:
            is_vip = False
            if friendship.sender == sender:
                is_vip = friendship.receiver_is_vip # Receiver considers ME a VIP?
            else:
                is_vip = friendship.sender_is_vip # Sender (ME) considers ME a VIP (wait, no).
                                                  # If I am receiver in friendship, then I check if SENDER (Me) is VIP? 
                                                  # No. If Friendship(Sender=Bob, Receiver=Alice). 
                                                  # Bob Pings Alice. Bob is Sender. 
                                                  # We check if Alice marked Bob as VIP. That is `receiver_is_vip`.
                                                  # If Alice Pings Bob. Alice is Sender (in Ping).
                                                  # We check if Bob marked Alice as VIP. That is `sender_is_vip`.
            if not is_vip:
                raise serializers.ValidationError("You are not a VIP for this user.")

        # 3. Rate Limit (Simple implementation)
        # Limit 'emergency' pings to 3 per day per pair (or sender)
        if attrs.get('ping_type') == 'emergency':
            today = timezone.now().date()
            daily_pings = Ping.objects.filter(
                sender=sender, 
                receiver=receiver, 
                ping_type='emergency',
                created_at__date=today
            ).count()
            
            if daily_pings >= 3:
                 raise serializers.ValidationError("Daily emergency limit reached for this friend.")

        return attrs

    def create(self, validated_data):
        sender = self.context['request'].user
        receiver = validated_data['receiver']
        return Ping.objects.create(
            sender=sender,
            
            # Pass all validated fields (lat, lon, audio, battery etc.)
             **{k: v for k, v in validated_data.items() if k != 'receiver'}
        )

class HandshakeSerializer(serializers.Serializer):
    message = serializers.CharField(max_length=255)

class RingtoneSerializer(serializers.Serializer):
    ringtone = serializers.CharField(max_length=50)

class CheckInSerializer(serializers.ModelSerializer):
    duration_minutes = serializers.IntegerField(write_only=True, required=False, default=30)

    class Meta:
        model = CheckInSession
        fields = ['id', 'started_at', 'expires_at', 'status', 'message', 'duration_minutes']
        read_only_fields = ['started_at', 'expires_at', 'status']

    def create(self, validated_data):
        user = self.context['request'].user
        duration = validated_data.pop('duration_minutes', 30)
        expires_at = timezone.now() + timedelta(minutes=duration)
        
        # Deactivate previous active sessions
        CheckInSession.objects.filter(user=user, status='active').update(status='safe')

        return CheckInSession.objects.create(
            user=user,
            expires_at=expires_at,
            message=validated_data.get('message', ''),
            **validated_data
        )

class UserSearchSerializer(serializers.ModelSerializer):
    nickname = serializers.CharField(source='profile.nickname', read_only=True)
    status = serializers.CharField(source='profile.status', read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'nickname', 'status']

class FriendListSerializer(serializers.ModelSerializer):
    nickname = serializers.CharField(source='profile.nickname', read_only=True)
    status = serializers.CharField(source='profile.status', read_only=True)
    last_online = serializers.DateTimeField(source='last_login', read_only=True)
    is_vip = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'nickname', 'status', 'is_vip', 'last_online']

    def get_is_vip(self, obj):
        # Obj is the Friend (User).
        # Context['request'].user is the Current User.
        user = self.context['request'].user
        
        # We need to find the friendship and check the flag relative to 'user'.
        # If 'user' is sender, check 'sender_is_vip'.
        # If 'user' is receiver, check 'receiver_is_vip'.
        
        # Optimization: This N+1 query is bad in production, but okay for this scale.
        # Ideally we'd prefetch this.
        friendship = Friendship.objects.filter(
            (Q(sender=user, receiver=obj) | Q(sender=obj, receiver=user)) &
            Q(status='accepted')
        ).first()
        
        if not friendship:
            return False
            
        if friendship.sender == user:
            return friendship.sender_is_vip
        else:
            return friendship.receiver_is_vip

class FriendRequestListSerializer(serializers.ModelSerializer):
    sender = UserSearchSerializer(read_only=True)
    receiver = UserSearchSerializer(read_only=True)
    
    class Meta:
        model = Friendship
        fields = ['id', 'sender', 'receiver', 'status', 'created_at']

class PingHistorySerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source='sender.username', read_only=True)
    receiver_name = serializers.CharField(source='receiver.username', read_only=True)

    class Meta:
        model = Ping
        fields = ['id', 'sender_name', 'receiver_name', 'ping_type', 'message', 'status', 'created_at', 'delivered_at']



