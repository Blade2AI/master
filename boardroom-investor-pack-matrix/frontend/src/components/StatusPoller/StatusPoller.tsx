import React, { useEffect, useState } from 'react';

const StatusPoller: React.FC = () => {
    const [status, setStatus] = useState<string>('Loading...');
    const [error, setError] = useState<string | null>(null);

    const fetchStatus = async () => {
        try {
            const response = await fetch('/api/status'); // Adjust the endpoint as necessary
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            const data = await response.json();
            setStatus(data.status);
        } catch (err) {
            setError(err.message);
        }
    };

    useEffect(() => {
        const intervalId = setInterval(fetchStatus, 5000); // Poll every 5 seconds
        return () => clearInterval(intervalId); // Cleanup on unmount
    }, []);

    return (
        <div>
            <h2>Status Poller</h2>
            {error ? (
                <p>Error: {error}</p>
            ) : (
                <p>Status: {status}</p>
            )}
        </div>
    );
};

export default StatusPoller;