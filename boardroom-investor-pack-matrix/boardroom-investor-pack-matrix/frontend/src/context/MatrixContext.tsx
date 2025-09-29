import React, { createContext, useContext, useState, useEffect } from 'react';
import { fetchMatrixData } from '../services/apiClient';
import { MatrixData } from '../types/api';

interface MatrixContextType {
    matrixData: MatrixData | null;
    loading: boolean;
    error: string | null;
}

const MatrixContext = createContext<MatrixContextType | undefined>(undefined);

export const MatrixProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [matrixData, setMatrixData] = useState<MatrixData | null>(null);
    const [loading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        const loadData = async () => {
            try {
                const data = await fetchMatrixData();
                setMatrixData(data);
            } catch (err) {
                setError('Failed to fetch matrix data');
            } finally {
                setLoading(false);
            }
        };

        loadData();
    }, []);

    return (
        <MatrixContext.Provider value={{ matrixData, loading, error }}>
            {children}
        </MatrixContext.Provider>
    );
};

export const useMatrixContext = (): MatrixContextType => {
    const context = useContext(MatrixContext);
    if (context === undefined) {
        throw new Error('useMatrixContext must be used within a MatrixProvider');
    }
    return context;
};