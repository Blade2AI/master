import axios from 'axios';

const apiClient = axios.create({
    baseURL: 'http://localhost:8000/api', // Adjust the base URL as needed
    headers: {
        'Content-Type': 'application/json',
    },
});

export const fetchMatrixData = async () => {
    try {
        const response = await apiClient.get('/matrix');
        return response.data;
    } catch (error) {
        console.error('Error fetching matrix data:', error);
        throw error;
    }
};

export const fetchStatus = async () => {
    try {
        const response = await apiClient.get('/status');
        return response.data;
    } catch (error) {
        console.error('Error fetching status:', error);
        throw error;
    }
};