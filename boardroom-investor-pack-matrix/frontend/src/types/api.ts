export interface MatrixData {
  id: string;
  name: string;
  status: 'pending' | 'in_progress' | 'completed' | 'failed';
  createdAt: string;
  updatedAt: string;
}

export interface ApiResponse<T> {
  data: T;
  message: string;
  success: boolean;
}

export interface StatusUpdate {
  id: string;
  status: 'pending' | 'in_progress' | 'completed' | 'failed';
  timestamp: string;
}