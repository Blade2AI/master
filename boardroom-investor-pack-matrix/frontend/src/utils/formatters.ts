export const formatCurrency = (amount: number): string => {
    return `$${amount.toFixed(2)}`;
};

export const formatPercentage = (value: number): string => {
    return `${(value * 100).toFixed(2)}%`;
};

export const formatDate = (date: Date): string => {
    return date.toLocaleDateString('en-US');
};

export const formatMatrixData = (data: any[]): any[] => {
    return data.map(item => ({
        ...item,
        formattedValue: formatCurrency(item.value),
        formattedDate: formatDate(new Date(item.date)),
    }));
};