document.addEventListener('DOMContentLoaded', () => {
  // DOM Elements
  const startButton = document.getElementById('startButton');
  const stopButton = document.getElementById('stopButton');
  const streamStatus = document.getElementById('streamStatus');
  const volumeSlider = document.getElementById('volumeSlider');
  const volumeValue = document.getElementById('volumeValue');
  const stationId = document.getElementById('stationId');
  const setStationButton = document.getElementById('setStationButton');
  
  // Check stream status
  const checkStatus = async () => {
    try {
      const response = await fetch('/api/stream/status');
      const data = await response.json();
      
      streamStatus.textContent = data.playing ? 'Playing' : 'Stopped';
      streamStatus.style.color = data.playing ? '#4CAF50' : '#f44336';
    } catch (error) {
      console.error('Error checking status:', error);
      streamStatus.textContent = 'Unknown';
      streamStatus.style.color = '#FFA500';
    }
  };
  
  // Start stream
  startButton.addEventListener('click', async () => {
    try {
      const station = stationId.value || 'default';
      
      // Disable the button during stream start attempt
      startButton.disabled = true;
      startButton.textContent = 'Starting...';
      
      const response = await fetch('/api/stream/start', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ stationId: station })
      });
      
      const data = await response.json();
      if (data.success) {
        checkStatus();
      } else if (data.message) {
        // Show error message to user
        streamStatus.textContent = `Error: ${data.message}`;
        streamStatus.style.color = '#f44336';
        console.error('Stream error:', data.message, data.details || '');
      }
    } catch (error) {
      console.error('Error starting stream:', error);
      streamStatus.textContent = 'Connection Error';
      streamStatus.style.color = '#f44336';
    } finally {
      // Re-enable the button
      startButton.disabled = false;
      startButton.textContent = 'Start Stream';
    }
  });
  
  // Stop stream
  stopButton.addEventListener('click', async () => {
    try {
      const response = await fetch('/api/stream/stop', {
        method: 'POST'
      });
      
      const data = await response.json();
      if (data.success) {
        checkStatus();
      }
    } catch (error) {
      console.error('Error stopping stream:', error);
    }
  });
  
  // Set volume
  volumeSlider.addEventListener('input', () => {
    const volume = volumeSlider.value;
    volumeValue.textContent = `${volume}%`;
  });
  
  volumeSlider.addEventListener('change', async () => {
    const volume = parseInt(volumeSlider.value);
    try {
      const response = await fetch('/api/stream/volume', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ volume })
      });
      
      await response.json();
    } catch (error) {
      console.error('Error setting volume:', error);
    }
  });
  
  // Check status initially
  checkStatus();
  // Check status every 5 seconds
  setInterval(checkStatus, 5000);
});
