<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens; // <-- ĐẢM BẢO CÓ DÒNG NÀY

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable; // <-- VÀ CÓ 'HasApiTokens' Ở ĐÂY

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'fcm_token', // <-- Thêm 'fcm_token' vào đây
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    // Định nghĩa mối quan hệ: 1 User có nhiều Task
    public function tasks()
    {
        return $this->hasMany(Task::class);
    }
}