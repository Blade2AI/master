import React from 'react';

const ClipboardButton: React.FC<{ text: string }> = ({ text }) => {
    const copyToClipboard = () => {
        navigator.clipboard.writeText(text).then(() => {
            alert('Copied to clipboard!');
        }).catch(err => {
            console.error('Failed to copy: ', err);
        });
    };

    return (
        <button onClick={copyToClipboard}>
            Copy to Clipboard
        </button>
    );
};

export default ClipboardButton;