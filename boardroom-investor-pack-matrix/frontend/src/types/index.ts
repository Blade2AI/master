export type MatrixData = {
  id: string;
  name: string;
  status: 'pending' | 'completed' | 'failed';
  createdAt: string;
  updatedAt: string;
};

export type StatusUpdate = {
  id: string;
  status: 'pending' | 'completed' | 'failed';
  message?: string;
};

export type ApiResponse<T> = {
  data: T;
  error?: string;
};