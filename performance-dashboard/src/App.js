import React, { useState, useEffect } from 'react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { 
  Box, 
  Container, 
  Grid, 
  Paper, 
  Typography, 
  FormControl, 
  InputLabel, 
  Select, 
  MenuItem,
  CircularProgress,
  Alert
} from '@mui/material';
import MultiplierComparison from './components/MultiplierComparison';
import AreaUtilization from './components/AreaUtilization';
import PowerConsumption from './components/PowerConsumption';
import CriticalPathDelay from './components/CriticalPathDelay';
import Throughput from './components/Throughput';
import { getMultiplierData } from './services/multiplierData';

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#90caf9',
    },
    secondary: {
      main: '#f48fb1',
    },
  },
});

function App() {
  const [selectedBitWidth, setSelectedBitWidth] = useState('all');
  const [selectedType, setSelectedType] = useState('all');
  const [multiplierData, setMultiplierData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const data = await getMultiplierData();
        setMultiplierData(data);
        setError(null);
      } catch (err) {
        setError('Failed to load multiplier data. Please try again later.');
        console.error('Error loading data:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const filteredData = multiplierData.filter(item => {
    const matchesBitWidth = selectedBitWidth === 'all' || 
      (selectedBitWidth === '8' && item.name.includes('8-bit')) ||
      (selectedBitWidth === '16' && item.name.includes('16-bit'));
    
    const matchesType = selectedType === 'all' ||
      (selectedType === 'signed' && item.name.includes('Signed')) ||
      (selectedType === 'unsigned' && item.name.includes('Unsigned'));

    return matchesBitWidth && matchesType;
  });

  if (loading) {
    return (
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh' 
      }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Container>
        <Alert severity="error" sx={{ mt: 2 }}>
          {error}
        </Alert>
      </Container>
    );
  }

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Box sx={{ flexGrow: 1, p: 3 }}>
        <Container maxWidth="xl">
          <Typography variant="h4" component="h1" gutterBottom>
            Multiplier Performance Analysis Dashboard
          </Typography>
          
          <Grid container spacing={2} sx={{ mb: 3 }}>
            <Grid item xs={12} sm={6} md={3}>
              <FormControl fullWidth>
                <InputLabel>Bit Width</InputLabel>
                <Select
                  value={selectedBitWidth}
                  label="Bit Width"
                  onChange={(e) => setSelectedBitWidth(e.target.value)}
                >
                  <MenuItem value="all">All</MenuItem>
                  <MenuItem value="8">8-bit</MenuItem>
                  <MenuItem value="16">16-bit</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <FormControl fullWidth>
                <InputLabel>Type</InputLabel>
                <Select
                  value={selectedType}
                  label="Type"
                  onChange={(e) => setSelectedType(e.target.value)}
                >
                  <MenuItem value="all">All</MenuItem>
                  <MenuItem value="signed">Signed</MenuItem>
                  <MenuItem value="unsigned">Unsigned</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>

          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Paper sx={{ p: 2 }}>
                <MultiplierComparison data={filteredData} />
              </Paper>
            </Grid>
            <Grid item xs={12} md={6}>
              <Paper sx={{ p: 2 }}>
                <AreaUtilization data={filteredData} />
              </Paper>
            </Grid>
            <Grid item xs={12} md={6}>
              <Paper sx={{ p: 2 }}>
                <PowerConsumption data={filteredData} />
              </Paper>
            </Grid>
            <Grid item xs={12} md={6}>
              <Paper sx={{ p: 2 }}>
                <CriticalPathDelay data={filteredData} />
              </Paper>
            </Grid>
            <Grid item xs={12} md={6}>
              <Paper sx={{ p: 2 }}>
                <Throughput data={filteredData} />
              </Paper>
            </Grid>
          </Grid>
        </Container>
      </Box>
    </ThemeProvider>
  );
}

export default App; 