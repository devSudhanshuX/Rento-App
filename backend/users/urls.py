from django.urls import path
from . import views

urlpatterns = [
    path('register', views.register_user, name='register_user'),
    path('support/report', views.create_support_ticket, name='create_support_ticket'),
    path('<str:user_id>/summary', views.profile_summary, name='profile_summary'),
    path('<str:user_id>/photo', views.upload_profile_photo, name='upload_profile_photo'),
    path('<str:user_id>', views.get_user, name='get_user'),
    path('<str:user_id>/update', views.update_user, name='update_user'),
]
