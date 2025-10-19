<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;

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
    // Route để lấy thông tin user hiện tại
    Route::get('/user', function (Request $request) {
        return $request->user();

    Route::post('/fcm-token', [AuthController::class, 'updateFcmToken']);
    });

    // === THÊM CÁC ROUTE CHO TASK VÀO ĐÂY ===
Route::get('/tasks', [App\Http\Controllers\TaskController::class, 'index']); // Lấy danh sách công việc
Route::post('/tasks', [App\Http\Controllers\TaskController::class, 'store']); // Thêm công việc mới
Route::get('/tasks/{task}', [App\Http\Controllers\TaskController::class, 'show']); // Lấy chi tiết 1 công việc
Route::put('/tasks/{task}', [App\Http\Controllers\TaskController::class, 'update']); // Cập nhật công việc
Route::delete('/tasks/{task}', [App\Http\Controllers\TaskController::class, 'destroy']); // Xóa công việc
Route::put('/user/profile', [ProfileController::class, 'update']);


});