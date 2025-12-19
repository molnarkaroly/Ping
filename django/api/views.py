from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers import (
    RegisterSerializer, 
    CustomTokenObtainPairSerializer, 
    UserProfileSerializer,
    FriendRequestSerializer,
    FriendshipActionSerializer,
    VIPSerializer,
    PingSerializer,
    UserSearchSerializer,
    FriendListSerializer,
    FriendRequestListSerializer,
    PingHistorySerializer,
    HandshakeSerializer,
    RingtoneSerializer,
    CheckInSerializer
)
from .models import UserProfile, Friendship, Ping, CheckInSession
from django.contrib.auth import get_user_model
from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiTypes
from django.db.models import Q
from rest_framework.generics import get_object_or_404
from django.utils import timezone

User = get_user_model()

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

    @extend_schema(
        summary="Login and obtain JWT pair",
        description="Takes username and password, returns access/refresh tokens and user profile data."
    )
    def post(self, request, *args, **kwargs):
        return super().post(request, *args, **kwargs)

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    # Note: permissions.AllowAny is important for registration
    permission_classes = (permissions.AllowAny,)
    serializer_class = RegisterSerializer

    @extend_schema(
        summary="Register a new user",
        description="Creates a new user account with the provided username, email, and password."
    )
    def post(self, request, *args, **kwargs):
        return super().post(request, *args, **kwargs)

class UpdateStatusView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        request=UserProfileSerializer,
        responses={200: UserProfileSerializer},
        summary="Update user status",
        description="Updates the authenticated user's availability status (e.g., 'available', 'driving', 'busy')."
    )
    def patch(self, request):
        user_profile = request.user.profile
        serializer = UserProfileSerializer(user_profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class UpdateFCMTokenView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        request=UserProfileSerializer,
        responses={200: UserProfileSerializer},
        summary="Update FCM Token",
        description="Updates the Firebase Cloud Messaging token for the authenticated user to enable push notifications."
    )
    def put(self, request):
        user_profile = request.user.profile
        # We expect {'fcm_token': '...'}
        serializer = UserProfileSerializer(user_profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SendFriendRequestView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        request=FriendRequestSerializer, 
        responses={201: None},
        summary="Send a friend request",
        description="Sends a friend request to another user. Cannot request self or duplicates."
    )
    def post(self, request):
        serializer = FriendRequestSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            receiver_id = serializer.validated_data['receiver_id']
            receiver = User.objects.get(id=receiver_id)
            Friendship.objects.create(sender=request.user, receiver=receiver, status='pending')
            return Response({'message': 'Friend request sent.'}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class RespondToFriendRequestView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        request=FriendshipActionSerializer, 
        responses={200: None},
        summary="Respond to friend request",
        description="Accept or Decline a pending friend request."
    )
    def patch(self, request, pk):
        try:
            friend_request = Friendship.objects.get(pk=pk, receiver=request.user, status='pending')
        except Friendship.DoesNotExist:
            return Response({'error': 'Friend request not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = FriendshipActionSerializer(data=request.data)
        if serializer.is_valid():
            action = serializer.validated_data['action']
            if action == 'accept':
                friend_request.status = 'accepted'
                friend_request.save()
                return Response({'message': 'Friend request accepted.'}, status=status.HTTP_200_OK)
            elif action == 'decline':
                friend_request.status = 'declined'
                friend_request.save()
                return Response({'message': 'Friend request declined.'}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class SetVIPStatusView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        request=VIPSerializer, 
        responses={200: None},
        summary="Set VIP status for a friend",
        description="Mark a friend as VIP to allow them to break through silent mode with Emergency Pings."
    )
    def patch(self, request, friend_id):
        user = request.user
        
        # Find friendship where user is either sender or receiver, AND it is accepted
        friendship = Friendship.objects.filter(
            (Q(sender=user, receiver_id=friend_id) | Q(sender_id=friend_id, receiver=user)) & 
            Q(status='accepted')
        ).first()

        if not friendship:
            return Response({'error': 'Friendship not found or not accepted.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = VIPSerializer(data=request.data)
        if serializer.is_valid():
            is_vip = serializer.validated_data['is_vip']
            if friendship.sender == user:
                friendship.sender_is_vip = is_vip
            else:
                friendship.receiver_is_vip = is_vip
            friendship.save()
            return Response({'message': 'VIP status updated.'}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class SendPingView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        request=PingSerializer, 
        responses={201: None},
        summary="Send an Emergency Ping",
        description="Send a ping (emergency, battery, etc.) to a friend. Requires friendship, VIP status (for emergency), and checks daily limits."
    )
    def post(self, request):
        serializer = PingSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            # TODO: Here we will later trigger Firebase Cloud Messaging (FCM)
            return Response({'message': 'Ping sent successfully.'}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class MarkPingDeliveredView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        responses={200: None},
        summary="Confirm Ping Delivery",
        description="Mark a ping as delivered and played on the device (Read Receipt)."
    )
    def post(self, request, pk):
        ping = get_object_or_404(Ping, pk=pk)

        # Only the receiver can mark it as delivered
        if ping.receiver != request.user:
            return Response({'error': 'Not authorized.'}, status=status.HTTP_403_FORBIDDEN)
        
        ping.status = 'delivered'
        ping.delivered_at = timezone.now()
        ping.save()
        
        return Response({'message': 'Ping marked as delivered.'}, status=status.HTTP_200_OK)

class FriendListView(generics.ListAPIView):
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = FriendListSerializer

    @extend_schema(
        summary="List Accepted Friends",
        description="Returns a list of all accepted friends, including their status, VIP status (outgoing), and online info."
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    def get_queryset(self):
        user = self.request.user
        # Find all accepted friendships
        friendships = Friendship.objects.filter(
            (Q(sender=user) | Q(receiver=user)) & 
            Q(status='accepted')
        )
        
        # Extract the 'other' user from each friendship
        friends = []
        for f in friendships:
            if f.sender == user:
                friends.append(f.receiver)
            else:
                friends.append(f.sender)
        
        return friends

class FriendRequestsListView(generics.ListAPIView):
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = FriendRequestListSerializer

    @extend_schema(
        summary="List Friend Requests",
        description="Returns all pending friend requests (both sent and received)."
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    def get_queryset(self):
        user = self.request.user
        # Return pending requests where user is sender OR receiver
        return Friendship.objects.filter(
            (Q(sender=user) | Q(receiver=user)) &
            Q(status='pending')
        )

class UnfriendView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        responses={200: None},
        summary="Unfriend a user",
        description="Removes the friendship connection between the current user and the specified friend."
    )
    def delete(self, request, friend_id):
        user = request.user
        # Find connection (accepted or pending)
        friendship = Friendship.objects.filter(
            (Q(sender=user, receiver_id=friend_id) | Q(sender_id=friend_id, receiver=user))
        ).exclude(status='blocked').first()

        if friendship:
            friendship.delete()
            return Response({'message': 'Friendship removed.'}, status=status.HTTP_200_OK)
        return Response({'error': 'Friendship not found.'}, status=status.HTTP_404_NOT_FOUND)

class BlockUserView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        responses={200: None},
        summary="Block a user",
        description="Blocks a user, preventing them from sending messages or requests."
    )
    def post(self, request, friend_id):
        user = request.user
        # Find connection
        friendship = Friendship.objects.filter(
            (Q(sender=user, receiver_id=friend_id) | Q(sender_id=friend_id, receiver=user))
        ).first()

        if not friendship:
            # Create blocked relationship if none exists
            try:
                other_user = User.objects.get(pk=friend_id)
                friendship = Friendship.objects.create(
                    sender=user, 
                    receiver=other_user, 
                    status='blocked', 
                    blocked_by=user
                )
            except User.DoesNotExist:
                return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
        else:
            friendship.status = 'blocked'
            friendship.blocked_by = user
            friendship.save()
            
        return Response({'message': 'User blocked.'}, status=status.HTTP_200_OK)

class UserSearchView(generics.ListAPIView):
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = UserSearchSerializer

    @extend_schema(
        summary="Search Users",
        description="Search for users by username or nickname."
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    def get_queryset(self):
        query = self.request.query_params.get('q', '')
        if not query:
            return User.objects.none()
        
        return User.objects.filter(
            Q(username__icontains=query) | 
            Q(profile__nickname__icontains=query)
        ).exclude(id=self.request.user.id)[:20] # Limit results

class UserProfileView(generics.RetrieveAPIView):
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = UserProfileSerializer

    @extend_schema(
        summary="Get Own Profile",
        description="Retrieve details of the currently authenticated user."
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    def get_object(self):
        return self.request.user.profile

class DeleteAccountView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        responses={200: None},
        summary="Delete Account",
        description="Permanently delete the current user's account."
    )
    def delete(self, request):
        user = request.user
        user.delete()
        return Response({'message': 'Account deleted.'}, status=status.HTTP_200_OK)

class LogoutView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        responses={200: None},
        summary="Logout",
        description="Logs out the user and clears their FCM token."
    )
    def post(self, request):
        # Clear FCM token
        if hasattr(request.user, 'profile'):
            request.user.profile.fcm_token = None
            request.user.profile.save()
        return Response({'message': 'Logged out successfully.'}, status=status.HTTP_200_OK)

class PingHistoryView(generics.ListAPIView):
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = PingHistorySerializer

    @extend_schema(
        summary="Ping History",
        description="Retrieve a list of recent sent and received pings."
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    def get_queryset(self):
        user = self.request.user
        return Ping.objects.filter(
            Q(sender=user) | Q(receiver=user)
        ).order_by('-created_at')[:50] # Limit to last 50

class UserLimitsView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        responses={200: None},
        summary="Daily Limits",
        description="Check how many emergency pings have been sent today."
    )
    def get(self, request):
        user = request.user
        today = timezone.now().date()
        
        # Count emergency pings sent today by user
        # Note: This is an approximation. Ideally we check per-friend limit.
        # But for "User Limits" endpoint, maybe we show global usage or just general info.
        # The prompt says: "how many emergency ping left for today (e.g. 3/1)".
        # Wait, the limit is PER FRIEND. 
        # So "User Limits" is a bit ambiguous if it aggregates everything.
        # But let's return the count for the most frequent friend or just total count?
        # Re-reading spec: "how many emergency ping left (e.g. 3/1)". 
        # This implies a global limit OR it assumes context.
        # Let's assume the spec meant "Global Limit" OR it meant "Show limits for all friends".
        # Simplest interpretation: Return total pings sent today.
        
        pings_sent = Ping.objects.filter(
            sender=user, 
            ping_type='emergency', 
            created_at__date=today
        ).count()
        
        return Response({
            'daily_emergency_pings_sent': pings_sent,
            'limit_per_friend': 3
        })

class HandshakeView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        request=HandshakeSerializer, 
        responses={200: None},
        summary="Send Handshake Response",
        description="Respond to an emergency ping with a predefined message (e.g., 'On my way')."
    )
    def post(self, request, pk):
        ping = get_object_or_404(Ping, pk=pk)
        
        # Only receiver can handshake
        if ping.receiver != request.user:
            return Response({'error': 'Not authorized.'}, status=status.HTTP_403_FORBIDDEN)
            
        serializer = HandshakeSerializer(data=request.data)
        if serializer.is_valid():
            ping.response_message = serializer.validated_data['message']
            ping.response_at = timezone.now()
            ping.save()
            return Response({'message': 'Handshake sent.'}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class SetRingtoneView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        request=RingtoneSerializer, 
        responses={200: None},
        summary="Set Friend Ringtone",
        description="Assign a custom ringtone identifier to a specific friend."
    )
    def patch(self, request, friend_id):
        user = request.user
        friendship = Friendship.objects.filter(
            (Q(sender=user, receiver_id=friend_id) | Q(sender_id=friend_id, receiver=user)) &
            Q(status='accepted')
        ).first()
        
        if not friendship:
            return Response({'error': 'Friendship not found.'}, status=status.HTTP_404_NOT_FOUND)
            
        serializer = RingtoneSerializer(data=request.data)
        if serializer.is_valid():
            friendship.ringtone = serializer.validated_data['ringtone']
            friendship.save()
            return Response({'message': 'Ringtone updated.'}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class CheckInStartView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        request=CheckInSerializer, 
        responses={201: None},
        summary="Start Check-In Timer",
        description="Start a 'Dead Man's Switch' timer. If not marked safe before expiration, an alert will be triggered (future impl)."
    )
    def post(self, request):
        serializer = CheckInSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class CheckInSafeView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    @extend_schema(
        responses={200: None},
        summary="Mark Safe (Check-In)",
        description="Mark the user as safe, stopping any active check-in timers."
    )
    def post(self, request):
        # Mark all active sessions as safe
        CheckInSession.objects.filter(
            user=request.user, 
            status='active'
        ).update(status='safe')
        return Response({'message': 'You are marked safe.'}, status=status.HTTP_200_OK)





