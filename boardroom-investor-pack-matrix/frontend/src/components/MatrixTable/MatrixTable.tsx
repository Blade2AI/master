import React from 'react';
import './MatrixTable.module.css';

interface MatrixTableProps {
    data: Array<Array<string | number>>;
}

const MatrixTable: React.FC<MatrixTableProps> = ({ data }) => {
    return (
        <table className="matrix-table">
            <thead>
                <tr>
                    {data[0].map((_, index) => (
                        <th key={index}>Column {index + 1}</th>
                    ))}
                </tr>
            </thead>
            <tbody>
                {data.slice(1).map((row, rowIndex) => (
                    <tr key={rowIndex}>
                        {row.map((cell, cellIndex) => (
                            <td key={cellIndex}>{cell}</td>
                        ))}
                    </tr>
                ))}
            </tbody>
        </table>
    );
};

export default MatrixTable;