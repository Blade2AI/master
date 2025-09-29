import { useEffect, useState } from 'react';

const useStatusPolling = (url: string, interval: number) => {
    const [status, setStatus] = useState(null);
    const [error, setError] = useState(null);

    useEffect(() => {
        const fetchStatus = async () => {
            try {
                const response = await fetch(url);
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                const data = await response.json();
                setStatus(data);
            } catch (err) {
                setError(err);
            }
        };

        fetchStatus();
        const pollingInterval = setInterval(fetchStatus, interval);

        return () => clearInterval(pollingInterval);
    }, [url, interval]);

    return { status, error };
};

export default useStatusPolling;