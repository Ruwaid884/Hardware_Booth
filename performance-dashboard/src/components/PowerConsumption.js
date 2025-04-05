import React from 'react';
import { Typography } from '@mui/material';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

const PowerConsumption = ({ data }) => {
  return (
    <div style={{ width: '100%', height: 300 }}>
      <Typography variant="h6" gutterBottom>
        Power Consumption (mW)
      </Typography>
      <ResponsiveContainer>
        <LineChart
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
          <Line
            type="monotone"
            dataKey="power"
            stroke="#8884d8"
            activeDot={{ r: 8 }}
            name="Power Consumption"
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

export default PowerConsumption; 