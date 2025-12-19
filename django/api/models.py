from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    nickname = models.CharField(max_length=50, blank=True)
    status = models.CharField(max_length=50, default='available')
    fcm_token = models.CharField(max_length=255, blank=True, null=True)

    def __str__(self):
        return f"{self.user.username}'s profile"

class Friendship(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('declined', 'Declined'),
        ('blocked', 'Blocked'),
    )
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_friend_requests')
    receiver = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_friend_requests')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    blocked_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='blocked_friendships')
    ringtone = models.CharField(max_length=50, default='default')
    
    # VIP flags: 
    # sender_is_vip=True means Sender considers Receiver a VIP.
    # receiver_is_vip=True means Receiver considers Sender a VIP.
    sender_is_vip = models.BooleanField(default=False)
    receiver_is_vip = models.BooleanField(default=False)

    class Meta:
        unique_together = ('sender', 'receiver')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.sender} -> {self.receiver} ({self.status})"

class Ping(models.Model):
    STATUS_CHOICES = (
        ('sent', 'Sent'),
        ('delivered', 'Delivered'),
    )
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_pings')
    receiver = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_pings')
    ping_type = models.CharField(max_length=20, default='emergency')
    message = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='sent')
    created_at = models.DateTimeField(auto_now_add=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    
    # Advanced / Pro features
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    audio_file = models.FileField(upload_to='pings/audio/', null=True, blank=True)
    battery_level = models.IntegerField(null=True, blank=True)
    
    # Handshake / Response
    response_message = models.TextField(null=True, blank=True)
    response_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Ping from {self.sender} to {self.receiver} at {self.created_at}"

class CheckInSession(models.Model):
    STATUS_CHOICES = (
        ('active', 'Active'),
        ('safe', 'Safe'),
        ('alerted', 'Alerted'),
    )
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='checkin_sessions')
    started_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    message = models.TextField(blank=True, help_text="Message to send if timer expires")

    def __str__(self):
        return f"CheckIn by {self.user} until {self.expires_at} ({self.status})"



