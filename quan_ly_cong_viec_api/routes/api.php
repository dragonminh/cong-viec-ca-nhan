<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\TaskController; // <-- THÊM DÒNG NÀY

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// == CÁC ROUTE CÔNG KHAI (Không cần đăng nhập) ==
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// == CÁC ROUTE ĐƯỢC BẢO VỆ (Yêu cầu phải đăng nhập và gửi token) ==
Route::middleware('auth:sanctum')->group(function () {
    
    // --- Quản lý User và Profile ---
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
    
    Route::post('/logout', [AuthController::class, 'logout']); // <-- Thêm route đăng xuất
    Route::post('/fcm-token', [AuthController::class, 'updateFcmToken']);
    Route::put('/user/profile', [ProfileController::class, 'update']);

    // --- Quản lý Công việc (Tasks) ---
    Route::get('/tasks', [TaskController::class, 'index']); // Lấy danh sách công việc
    Route::post('/tasks', [TaskController::class, 'store']); // Thêm công việc mới
    Route::get('/tasks/{task}', [TaskController::class, 'show']); // Lấy chi tiết 1 công việc
    Route::put('/tasks/{task}', [TaskController::class, 'update']); // Cập nhật công việc
    Route::delete('/tasks/{task}', [TaskController::class, 'destroy']); // Xóa công việc
});