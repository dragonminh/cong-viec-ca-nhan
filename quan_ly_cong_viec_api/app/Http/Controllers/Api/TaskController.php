<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Task;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TaskController extends Controller
{
    /**
     * Display a listing of the resource.
     * HIỂN THỊ DANH SÁCH CÔNG VIỆC (HÀM BỊ THIẾU CỦA BẠN LÀ ĐÂY)
     */
    public function index()
    {
        // Lấy tất cả công việc CỦA user đang đăng nhập
        $tasks = Auth::user()->tasks()->orderBy('due_date', 'asc')->get();
        return response()->json($tasks);
    }

    /**
     * Store a newly created resource in storage.
     * LƯU CÔNG VIỆC MỚI
     */
    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'note' => 'nullable|string',
            'due_date' => 'required|date_format:Y-m-d',
            'due_time' => 'nullable|date_format:H:i', // Sửa: Dùng H:i cho '14:30'
            'is_fixed' => 'nullable|boolean',
            'type' => 'nullable|string',
        ]);

        $task = Auth::user()->tasks()->create([
            'title' => $request->title,
            'note' => $request->note,
            'due_date' => $request->due_date,
            'due_time' => $request->due_time,
            'is_fixed' => $request->input('is_fixed', false),
            'type' => $request->type,
        ]);

        return response()->json($task, 201); // 201 Created
    }

    /**
     * Display the specified resource.
     * HIỂN THỊ 1 CÔNG VIỆC CỤ THỂ
     */
    public function show(Task $task)
    {
        // Đảm bảo user chỉ xem được task của chính mình
        if ($task->user_id !== Auth::id()) {
            return response()->json(['message' => 'Không tìm thấy công việc'], 404);
        }
        return response()->json($task);
    }

    /**
     * Update the specified resource in storage.
     * CẬP NHẬT CÔNG VIỆC
     */
    public function update(Request $request, Task $task)
    {
        // Đảm bảo user chỉ cập nhật được task của chính mình
        if ($task->user_id !== Auth::id()) {
            return response()->json(['message' => 'Không tìm thấy công việc'], 404);
        }

        $request->validate([
            'title' => 'sometimes|string|max:255',
            'note' => 'nullable|string',
            'due_date' => 'sometimes|date_format:Y-m-d',
            'due_time' => 'nullable|date_format:H:i',
            'is_completed' => 'sometimes|boolean',
            'is_fixed' => 'sometimes|boolean',
            'type' => 'nullable|string',
        ]);

        $task->update($request->all());

        return response()->json($task);
    }

    /**
     * Remove the specified resource from storage.
     * XÓA CÔNG VIỆC
     */
    public function destroy(Task $task)
    {
        // Đảm bảo user chỉ xóa được task của chính mình
        if ($task->user_id !== Auth::id()) {
            return response()->json(['message' => 'Không tìm thấy công việc'], 404);
        }

        $task->delete();

        return response()->json(null, 204); // 204 No Content
    }
}