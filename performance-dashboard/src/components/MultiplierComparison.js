import React from 'react';
import { Typography, Box } from '@mui/material';
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

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <Box sx={{ 
        backgroundColor: 'rgba(255, 255, 255, 0.9)',
        padding: '10px',
        borderRadius: '4px',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
      }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 'bold' }}>{label}</Typography>
        {payload.map((entry, index) => (
          <Typography key={index} sx={{ color: entry.color }}>
            {entry.name}: {entry.value} {entry.name === 'Area' ? 'gates' : 
              entry.name === 'Power' ? 'mW' : 
              entry.name === 'Delay' ? 'ns' : 'MHz'}
          </Typography>
        ))}
      </Box>
    );
  }
  return null;
};

const MultiplierComparison = ({ data }) => {
  return (
    <Box sx={{ width: '100%', height: 400 }}>
      <Typography variant="h6" gutterBottom>
        Multiplier Performance Comparison
      </Typography>
      <ResponsiveContainer>
        <BarChart
          data={data}
          margin={{
            top: 20,
            right: 30,
            left: 20,
            bottom: 5,
          }}
        >
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis 
            dataKey="name" 
            angle={-45} 
            textAnchor="end" 
            height={100}
            tick={{ fill: '#fff' }}
          />
          <YAxis 
            yAxisId="left" 
            orientation="left" 
            stroke="#8884d8"
            tick={{ fill: '#fff' }}
          />
          <YAxis 
            yAxisId="right" 
            orientation="right" 
            stroke="#82ca9d"
            tick={{ fill: '#fff' }}
          />
          <Tooltip content={<CustomTooltip />} />
          <Legend />
          <Bar 
            yAxisId="left" 
            dataKey="area" 
            name="Area" 
            fill="#8884d8" 
            radius={[4, 4, 0, 0]}
          />
          <Bar 
            yAxisId="right" 
            dataKey="power" 
            name="Power" 
            fill="#82ca9d" 
            radius={[4, 4, 0, 0]}
          />
          <Bar 
            yAxisId="left" 
            dataKey="delay" 
            name="Delay" 
            fill="#ffc658" 
            radius={[4, 4, 0, 0]}
          />
          <Bar 
            yAxisId="right" 
            dataKey="throughput" 
            name="Throughput" 
            fill="#ff8042" 
            radius={[4, 4, 0, 0]}
          />
        </BarChart>
      </ResponsiveContainer>
    </Box>
  );
};

export default MultiplierComparison; 