from django.urls import path
from .views import (
    RegisterView, CustomTokenObtainPairView, UpdateStatusView, UpdateFCMTokenView,
    RegisterView, CustomTokenObtainPairView, UpdateStatusView, UpdateFCMTokenView,
    SendFriendRequestView, RespondToFriendRequestView, SetVIPStatusView,
    SendPingView, MarkPingDeliveredView,
    FriendListView, FriendRequestsListView, UnfriendView, BlockUserView,
    UserSearchView, UserProfileView, DeleteAccountView, LogoutView,
    PingHistoryView, UserLimitsView,
    HandshakeView, SetRingtoneView, CheckInStartView, CheckInSafeView
)
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('auth/register/', RegisterView.as_view(), name='register'),
    path('auth/login/', CustomTokenObtainPairView.as_view(), name='login'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    path('user/status/', UpdateStatusView.as_view(), name='update_status'),
    path('user/fcm-token/', UpdateFCMTokenView.as_view(), name='update_fcm_token'),

    path('friends/', FriendListView.as_view(), name='friend_list'),
    path('friends/requests/', FriendRequestsListView.as_view(), name='friend_requests'),
    path('friends/request/', SendFriendRequestView.as_view(), name='send_friend_request'),
    path('friends/request/<int:pk>/', RespondToFriendRequestView.as_view(), name='respond_friend_request'),
    path('friends/<int:friend_id>/', UnfriendView.as_view(), name='unfriend'),
    path('friends/<int:friend_id>/block/', BlockUserView.as_view(), name='block_user'),
    path('friends/<int:friend_id>/vip/', SetVIPStatusView.as_view(), name='set_vip_status'),

    path('user/search/', UserSearchView.as_view(), name='user_search'),
    path('user/profile/', UserProfileView.as_view(), name='user_profile'),
    path('user/me/', DeleteAccountView.as_view(), name='delete_account'),
    path('auth/logout/', LogoutView.as_view(), name='logout'),

    path('pings/send/', SendPingView.as_view(), name='send_ping'),
    path('pings/<int:pk>/delivered/', MarkPingDeliveredView.as_view(), name='mark_ping_delivered'),
    path('pings/<int:pk>/handshake/', HandshakeView.as_view(), name='send_handshake'),
    path('pings/history/', PingHistoryView.as_view(), name='ping_history'),
    
    path('user/limits/', UserLimitsView.as_view(), name='user_limits'),
    path('user/checkin/start/', CheckInStartView.as_view(), name='checkin_start'),
    path('user/checkin/safe/', CheckInSafeView.as_view(), name='checkin_safe'),
]
