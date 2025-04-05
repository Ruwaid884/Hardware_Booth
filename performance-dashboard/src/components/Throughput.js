import React from 'react';
import { Typography } from '@mui/material';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

const Throughput = ({ data }) => {
  return (
    <div style={{ width: '100%', height: 300 }}>
      <Typography variant="h6" gutterBottom>
        Throughput (MHz)
      </Typography>
      <ResponsiveContainer>
        <AreaChart
          data={data}
          margin={{
            top: 10,
            right: 30,
            left: 0,
            bottom: 0,
          }}
        >
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="name" angle={-45} textAnchor="end" height={60} />
          <YAxis />
          <Tooltip />
          <Legend />
          <Area
            type="monotone"
            dataKey="throughput"
            stackId="1"
            stroke="#8884d8"
            fill="#8884d8"
            name="Throughput"
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
};

export default Throughput; 