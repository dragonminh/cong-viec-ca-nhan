<?php

namespace App\Http\Controllers;

use App\Models\Task;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class TaskController extends Controller
{
    /**
     * Lấy danh sách công việc của người dùng đã đăng nhập.
     */
    public function index()
    {
        $tasks = Auth::user()->tasks()->orderBy('due_date', 'asc')->get();
        return response()->json($tasks);
    }

    /**
     * Lưu một công việc mới.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'note' => 'nullable|string',
            'due_date' => 'required|date',
            'is_fixed' => 'sometimes|boolean',
            'type' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $task = Auth::user()->tasks()->create($request->all());

        return response()->json($task, 201);
    }

    /**
     * Hiển thị chi tiết một công việc.
     */
    public function show(Task $task)
    {
        // Chỉ cho phép user xem task của chính họ
        if ($task->user_id !== Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        return response()->json($task);
    }

    /**
     * Cập nhật một công việc.
     */
    public function update(Request $request, Task $task)
    {
        // Chỉ cho phép user cập nhật task của chính họ
        if ($task->user_id !== Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|required|string|max:255',
            'note' => 'nullable|string',
            'due_date' => 'sometimes|required|date',
            'is_completed' => 'sometimes|boolean',
            'is_fixed' => 'sometimes|boolean',
            'type' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $task->update($request->all());

        return response()->json($task);
    }

    /**
     * Xóa một công việc.
     */
    public function destroy(Task $task)
    {
        // Chỉ cho phép user xóa task của chính họ
        if ($task->user_id !== Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $task->delete();

        return response()->json(null, 204); // 204 No Content
    }
}