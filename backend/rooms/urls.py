from django.urls import path
from . import views

urlpatterns = [
    path('', views.get_all_rooms, name='get_all_rooms'),
    path('create', views.create_room, name='create_room'),
    path('images/upload', views.upload_room_images, name='upload_room_images'),
    path('owner/<str:owner_id>', views.get_rooms_by_owner, name='get_rooms_by_owner'),
    path('saved/toggle', views.toggle_saved_room, name='toggle_saved_room'),
    path('saved/<str:user_id>', views.get_saved_rooms, name='get_saved_rooms'),
    path('notifications/create', views.create_notification, name='create_notification'),
    path('notifications/<uuid:notification_id>/read', views.mark_notification_read, name='mark_notification_read'),
    path('notifications/<str:user_id>', views.get_notifications, name='get_notifications'),
    path('inquiries/create', views.create_inquiry, name='create_inquiry'),
    path('inquiries/owner/<str:owner_id>', views.get_owner_inquiries, name='get_owner_inquiries'),
    path('inquiries/tenant/<str:tenant_id>', views.get_tenant_inquiries, name='get_tenant_inquiries'),
    path('reviews/create', views.create_review, name='create_review'),
    path('reviews/received/<str:user_id>', views.get_reviews_for_user, name='get_reviews_for_user'),
    path('reviews/given/<str:user_id>', views.get_reviews_by_user, name='get_reviews_by_user'),
    path('<str:room_id>', views.room_detail, name='room_detail'),
]
