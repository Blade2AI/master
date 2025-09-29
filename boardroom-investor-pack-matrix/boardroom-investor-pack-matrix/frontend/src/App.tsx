import React from 'react';
import { MatrixProvider } from './context/MatrixContext';
import Dashboard from './components/Dashboard/Dashboard';

const App: React.FC = () => {
  return (
    <MatrixProvider>
      <Dashboard />
    </MatrixProvider>
  );
};

export default App;