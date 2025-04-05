import React from 'react';
import { Typography } from '@mui/material';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

const CriticalPathDelay = ({ data }) => {
  return (
    <div style={{ width: '100%', height: 300 }}>
      <Typography variant="h6" gutterBottom>
        Critical Path Delay (ns)
      </Typography>
      <ResponsiveContainer>
        <BarChart
          data={data}
          margin={{
            top: 5,
            right: 30,
            left: 20,
            bottom: 5,
          }}
        >
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="name" angle={-45} textAnchor="end" height={60} />
          <YAxis />
          <Tooltip />
          <Legend />
          <Bar dataKey="delay" fill="#8884d8" name="Critical Path Delay" />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
};

export default CriticalPathDelay; 