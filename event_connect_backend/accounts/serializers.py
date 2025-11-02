from django.contrib.auth.models import User
from rest_framework import serializers

from .models import Profile


class ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = Profile
        fields = ('role', 'display_name', 'bio', 'student_id', 'club_name', 'school_code')


class UserSerializer(serializers.ModelSerializer):
    profile = ProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'profile')


class RegisterSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)
    email = serializers.EmailField(required=False, allow_blank=True)
    role = serializers.ChoiceField(choices=Profile.ROLE_CHOICES, default=Profile.ROLE_STUDENT)
    display_name = serializers.CharField(required=False, allow_blank=True)
    student_id = serializers.CharField(required=False, allow_blank=True)
    club_name = serializers.CharField(required=False, allow_blank=True)
    school_code = serializers.CharField(required=False, allow_blank=True)

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError('username already exists')
        return value

    def create(self, validated_data):
        username = validated_data.get('username')
        password = validated_data.get('password')
        email = validated_data.get('email', '')
        role = validated_data.get('role', Profile.ROLE_STUDENT)
        display_name = validated_data.get('display_name', '')

        user = User.objects.create_user(username=username, email=email, password=password)
        profile = user.profile if hasattr(user, 'profile') else Profile.objects.create(user=user)
        profile.role = role
        profile.display_name = display_name
        profile.student_id = validated_data.get('student_id', '')
        profile.club_name = validated_data.get('club_name', '')
        profile.school_code = validated_data.get('school_code', '')
        profile.save()
        return user
