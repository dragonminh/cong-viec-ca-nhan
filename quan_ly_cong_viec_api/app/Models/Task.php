<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Task extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'title',
        'note',
        'due_date',
        'due_time', // <-- ĐÃ THÊM
        'is_completed',
        'is_fixed',
        'type',
        'user_id',
    ];

    /**
     * The attributes that should be cast.
     * Giúp Laravel tự động chuyển đổi kiểu dữ liệu.
     * @var array<string, string>
     */
    protected $casts = [
        'is_completed' => 'boolean',
        'is_fixed' => 'boolean',
    ];

    /**
     * Lấy user sở hữu công việc này.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

