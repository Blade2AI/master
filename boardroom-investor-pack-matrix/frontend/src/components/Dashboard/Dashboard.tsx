import React from 'react';
import { useMatrixData } from '../../hooks/useMatrixData';
import { useStatusPolling } from '../../hooks/useStatusPolling';
import MatrixTable from '../MatrixTable/MatrixTable';
import StatusPoller from '../StatusPoller/StatusPoller';
import ClipboardButton from '../ClipboardButton/ClipboardButton';
import styles from './Dashboard.module.css';

const Dashboard: React.FC = () => {
    const { matrixData, loading, error } = useMatrixData();
    const { status } = useStatusPolling();

    if (loading) {
        return <div>Loading...</div>;
    }

    if (error) {
        return <div>Error loading data: {error.message}</div>;
    }

    return (
        <div className={styles.dashboard}>
            <h1>Investor Pack Matrix Dashboard</h1>
            <StatusPoller status={status} />
            <MatrixTable data={matrixData} />
            <ClipboardButton text={JSON.stringify(matrixData)} />
        </div>
    );
};

export default Dashboard;