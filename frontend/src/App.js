import React, { useState, useEffect, useRef } from 'react';
import './App.css';

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

function App() {
  const [stations, setStations] = useState([]);
  const [currentStation, setCurrentStation] = useState(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [loading, setLoading] = useState(true);
  const [countries, setCountries] = useState([]);
  const [selectedCountry, setSelectedCountry] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [error, setError] = useState('');
  const audioRef = useRef(null);

  // Fetch initial data
  useEffect(() => {
    fetchPopularStations();
    fetchCountries();
  }, []);

  const fetchPopularStations = async () => {
    try {
      setLoading(true);
      setError('');
      
      console.log('Fetching stations from:', `${API}/radio/stations/popular?limit=100`);
      const response = await fetch(`${API}/radio/stations/popular?limit=100`);
      
      console.log('Response status:', response.status);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      console.log('Received data:', data);
      console.log('Data length:', data.length);
      
      if (Array.isArray(data)) {
        console.log('Setting stations:', data.length);
        setStations(data);
        console.log('Stations set successfully');
      } else {
        throw new Error('Invalid response format');
      }
    } catch (err) {
      console.error('Error fetching stations:', err);
      setError('Unable to load radio stations. Please try again.');
    } finally {
      console.log('Setting loading to false');
      setLoading(false);
    }
  };

  const fetchCountries = async () => {
    try {
      const response = await fetch(`${API}/radio/countries`);

      if (response.ok) {
        const data = await response.json();
        if (Array.isArray(data)) {
          // Sort by station count and take top 50
          const sortedCountries = data
            .filter(country => country.stationcount > 0)
            .sort((a, b) => b.stationcount - a.stationcount)
            .slice(0, 50);
          setCountries(sortedCountries);
        }
      }
    } catch (err) {
      console.error('Error fetching countries:', err);
    }
  };

  const searchStations = async () => {
    try {
      setLoading(true);
      setError('');
      
      let url = `${API}/radio/stations/search?limit=100`;
      
      if (searchTerm.trim()) {
        url += `&name=${encodeURIComponent(searchTerm.trim())}`;
      }
      if (selectedCountry) {
        url += `&country=${encodeURIComponent(selectedCountry)}`;
      }

      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      
      if (Array.isArray(data)) {
        setStations(data);
      } else {
        throw new Error('Invalid response format');
      }
    } catch (err) {
      console.error('Error searching stations:', err);
      setError('Search failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const playStation = async (station) => {
    try {
      if (currentStation && currentStation.stationuuid === station.stationuuid && isPlaying) {
        audioRef.current.pause();
        setIsPlaying(false);
        return;
      }

      // Register click with our backend
      try {
        await fetch(`${API}/radio/stations/${station.stationuuid}/click`, {
          method: 'POST'
        });
      } catch (e) {
        // Ignore click registration errors
      }

      setCurrentStation(station);
      audioRef.current.src = station.url_resolved || station.url;
      
      try {
        await audioRef.current.play();
        setIsPlaying(true);
        setError('');
      } catch (playError) {
        console.error('Playback error:', playError);
        setError(`Cannot play "${station.name}". This station may be offline.`);
        setIsPlaying(false);
      }
    } catch (err) {
      console.error('Error playing station:', err);
      setError('Playback failed. Please try another station.');
    }
  };

  const stopPlayback = () => {
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current.currentTime = 0;
    }
    setIsPlaying(false);
    setCurrentStation(null);
  };

  const handleAudioError = () => {
    setError(currentStation ? `"${currentStation.name}" is not available.` : 'Audio error occurred.');
    setIsPlaying(false);
  };

  const resetToPopular = () => {
    setSelectedCountry('');
    setSearchTerm('');
    fetchPopularStations();
  };

  const handleSearch = (e) => {
    e.preventDefault();
    searchStations();
  };

  return (
    <div className="min-h-screen bg-white">
      <audio 
        ref={audioRef} 
        onError={handleAudioError}
        onEnded={() => setIsPlaying(false)}
        onPause={() => setIsPlaying(false)}
        onPlay={() => setIsPlaying(true)}
        crossOrigin="anonymous"
      />
      
      {/* Header */}
      <header className="border-b border-gray-200 bg-white sticky top-0 z-10">
        <div className="max-w-6xl mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-black rounded-full flex items-center justify-center">
                <span className="text-white text-sm font-bold">R</span>
              </div>
              <div>
                <h1 className="text-2xl font-light text-black">Global Radio</h1>
                <p className="text-gray-500 text-sm">Worldwide stations</p>
              </div>
            </div>
            
            {currentStation && (
              <div className="hidden md:flex items-center space-x-4">
                <div className="text-right">
                  <p className="font-medium text-gray-900">{currentStation.name}</p>
                  <p className="text-sm text-gray-500">{currentStation.country}</p>
                </div>
                <div className="flex space-x-2">
                  <button
                    onClick={() => playStation(currentStation)}
                    className="w-10 h-10 bg-black text-white rounded-full flex items-center justify-center hover:bg-gray-800 transition-colors"
                  >
                    {isPlaying ? '⏸' : '▶'}
                  </button>
                  <button
                    onClick={stopPlayback}
                    className="w-10 h-10 bg-gray-200 text-gray-700 rounded-full flex items-center justify-center hover:bg-gray-300 transition-colors"
                  >
                    ⏹
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </header>

      {/* Search Controls */}
      <div className="max-w-6xl mx-auto px-4 py-6">
        <form onSubmit={handleSearch} className="bg-gray-50 rounded-lg p-6 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
            <input
              type="text"
              placeholder="Search stations..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-black focus:border-transparent"
            />
            
            <select
              value={selectedCountry}
              onChange={(e) => setSelectedCountry(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-black focus:border-transparent"
            >
              <option value="">All Countries</option>
              {countries.map((country) => (
                <option key={country.name} value={country.name}>
                  {country.name} ({country.stationcount})
                </option>
              ))}
            </select>

            <div className="flex space-x-2">
              <button
                type="submit"
                className="flex-1 bg-black text-white px-4 py-3 rounded-lg hover:bg-gray-800 transition-colors font-medium"
              >
                Search
              </button>
              <button
                type="button"
                onClick={resetToPopular}
                className="px-4 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              >
                Reset
              </button>
            </div>
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
              {error}
            </div>
          )}
        </form>

        {/* Current Playing */}
        {currentStation && (
          <div className="bg-black text-white rounded-lg p-6 mb-6">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-xl font-medium mb-1">{currentStation.name}</h3>
                <p className="text-gray-300">{currentStation.country}</p>
                {currentStation.tags && (
                  <p className="text-gray-400 text-sm mt-1">{currentStation.tags}</p>
                )}
              </div>
              <div className="flex space-x-2">
                <button
                  onClick={() => playStation(currentStation)}
                  className="w-12 h-12 bg-white text-black rounded-full flex items-center justify-center hover:bg-gray-200 transition-colors"
                >
                  {isPlaying ? '⏸' : '▶'}
                </button>
                <button
                  onClick={stopPlayback}
                  className="w-12 h-12 bg-gray-800 text-white rounded-full flex items-center justify-center hover:bg-gray-700 transition-colors"
                >
                  ⏹
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Debug Info */}
        <div className="bg-yellow-50 border border-yellow-200 p-4 mb-4 rounded-lg">
          <p className="text-sm">Debug: Loading={loading.toString()}, Stations={stations.length}, Error={error || 'none'}</p>
          <p className="text-sm">API URL: {API}</p>
        </div>

        {/* Loading State */}
        {loading && (
          <div className="text-center py-12">
            <div className="inline-block w-6 h-6 border-2 border-gray-300 border-t-black rounded-full animate-spin"></div>
            <p className="text-gray-600 mt-4">Loading stations...</p>
          </div>
        )}

        {/* Stations Grid */}
        {!loading && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {stations.map((station) => (
              <div
                key={station.stationuuid}
                className={`border rounded-lg p-4 hover:shadow-md transition-all cursor-pointer ${
                  currentStation && currentStation.stationuuid === station.stationuuid
                    ? 'border-black bg-gray-50'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
                onClick={() => playStation(station)}
              >
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1 min-w-0">
                    <h3 className="font-medium text-gray-900 truncate">{station.name}</h3>
                    <p className="text-gray-600 text-sm">{station.country}</p>
                  </div>
                  <button className="ml-3 text-xl text-gray-400 hover:text-black transition-colors">
                    {currentStation && currentStation.stationuuid === station.stationuuid && isPlaying ? '⏸' : '▶'}
                  </button>
                </div>
                
                {station.tags && (
                  <p className="text-gray-500 text-xs mb-2 truncate">{station.tags}</p>
                )}
                
                <div className="flex justify-between items-center text-xs text-gray-400">
                  <span>{station.votes || 0} votes</span>
                  {station.bitrate && <span>{station.bitrate} kbps</span>}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Empty State */}
        {!loading && stations.length === 0 && (
          <div className="text-center py-12">
            <p className="text-gray-900 text-xl font-light">No stations found</p>
            <p className="text-gray-500 mt-2">Try adjusting your search criteria</p>
          </div>
        )}
      </div>

      {/* Footer */}
      <footer className="border-t border-gray-200 bg-gray-50 mt-12">
        <div className="max-w-6xl mx-auto px-4 py-6 text-center">
          <p className="text-gray-500 text-sm">
            Powered by{' '}
            <a 
              href="https://www.radio-browser.info" 
              target="_blank" 
              rel="noopener noreferrer"
              className="text-black hover:underline"
            >
              Radio Browser
            </a>
          </p>
        </div>
      </footer>
    </div>
  );
}

export default App;