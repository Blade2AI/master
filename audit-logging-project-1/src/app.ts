import express from 'express';
import { createLogger, format, transports } from 'winston';
import path from 'path';

const app = express();
const PORT = process.env.PORT || 3000;

const logger = createLogger({
    level: 'info',
    format: format.combine(
        format.timestamp(),
        format.json()
    ),
    transports: [
        new transports.File({ filename: path.join(__dirname, '../ops/logs/audit.log') })
    ]
});

app.use(express.json());

app.get('/', (req, res) => {
    logger.info('Root endpoint accessed');
    res.send('Welcome to the Audit Logging Project!');
});

app.listen(PORT, () => {
    logger.info(`Server is running on port ${PORT}`);
});