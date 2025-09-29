import { useEffect, useState } from 'react';
import { fetchMatrixData } from '../services/apiClient';
import { MatrixData } from '../types/api';

const useMatrixData = () => {
    const [matrixData, setMatrixData] = useState<MatrixData | null>(null);
    const [loading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        const loadMatrixData = async () => {
            try {
                const data = await fetchMatrixData();
                setMatrixData(data);
            } catch (err) {
                setError('Failed to fetch matrix data');
            } finally {
                setLoading(false);
            }
        };

        loadMatrixData();
    }, []);

    return { matrixData, loading, error };
};

export default useMatrixData;