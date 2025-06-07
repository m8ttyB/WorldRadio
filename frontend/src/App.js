import React, { useState, useEffect, useRef } from 'react';
import './App.css';

// Radio Browser API Base URL
const RADIO_API_BASE = 'https://de1.api.radio-browser.info';

function App() {
  const [stations, setStations] = useState([]);
  const [currentStation, setCurrentStation] = useState(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [loading, setLoading] = useState(true);
  const [countries, setCountries] = useState([]);
  const [selectedCountry, setSelectedCountry] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [genres, setGenres] = useState([]);
  const [selectedGenre, setSelectedGenre] = useState('');
  const [error, setError] = useState('');
  const audioRef = useRef(null);

  // Fetch initial data
  useEffect(() => {
    fetchPopularStations();
    fetchCountries();
    fetchGenres();
  }, []);

  const fetchPopularStations = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${RADIO_API_BASE}/json/stations/topvote/100`, {
        headers: {
          'User-Agent': 'GlobalRadioApp/1.0'
        }
      });
      const data = await response.json();
      setStations(data);
      setError('');
    } catch (err) {
      setError('Failed to load radio stations');
      console.error('Error fetching stations:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchCountries = async () => {
    try {
      const response = await fetch(`${RADIO_API_BASE}/json/countries`, {
        headers: {
          'User-Agent': 'GlobalRadioApp/1.0'
        }
      });
      const data = await response.json();
      setCountries(data.slice(0, 50)); // Limit to top 50 countries
    } catch (err) {
      console.error('Error fetching countries:', err);
    }
  };

  const fetchGenres = async () => {
    try {
      const response = await fetch(`${RADIO_API_BASE}/json/tags?limit=30`, {
        headers: {
          'User-Agent': 'GlobalRadioApp/1.0'
        }
      });
      const data = await response.json();
      setGenres(data);
    } catch (err) {
      console.error('Error fetching genres:', err);
    }
  };

  const searchStations = async () => {
    try {
      setLoading(true);
      let url = `${RADIO_API_BASE}/json/stations/search?limit=100`;
      
      if (searchTerm) {
        url += `&name=${encodeURIComponent(searchTerm)}`;
      }
      if (selectedCountry) {
        url += `&country=${encodeURIComponent(selectedCountry)}`;
      }
      if (selectedGenre) {
        url += `&tag=${encodeURIComponent(selectedGenre)}`;
      }

      const response = await fetch(url, {
        headers: {
          'User-Agent': 'GlobalRadioApp/1.0'
        }
      });
      const data = await response.json();
      setStations(data);
      setError('');
    } catch (err) {
      setError('Failed to search stations');
      console.error('Error searching stations:', err);
    } finally {
      setLoading(false);
    }
  };

  const playStation = async (station) => {
    try {
      if (currentStation && currentStation.stationuuid === station.stationuuid && isPlaying) {
        // Pause current station
        audioRef.current.pause();
        setIsPlaying(false);
        return;
      }

      // Register click with Radio Browser API
      await fetch(`${RADIO_API_BASE}/json/url/${station.stationuuid}`, {
        method: 'POST',
        headers: {
          'User-Agent': 'GlobalRadioApp/1.0'
        }
      });

      setCurrentStation(station);
      audioRef.current.src = station.url_resolved || station.url;
      
      try {
        await audioRef.current.play();
        setIsPlaying(true);
        setError('');
      } catch (playError) {
        console.error('Playback error:', playError);
        setError(`Failed to play ${station.name}. This station might be offline.`);
        setIsPlaying(false);
      }
    } catch (err) {
      console.error('Error playing station:', err);
      setError('Failed to play station');
    }
  };

  const handleAudioError = () => {
    setError(currentStation ? `Failed to play ${currentStation.name}. This station might be offline.` : 'Audio playback error');
    setIsPlaying(false);
  };

  const clearFilters = () => {
    setSelectedCountry('');
    setSelectedGenre('');
    setSearchTerm('');
    fetchPopularStations();
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-900 via-purple-900 to-pink-800">
      <audio 
        ref={audioRef} 
        onError={handleAudioError}
        onEnded={() => setIsPlaying(false)}
        onPause={() => setIsPlaying(false)}
        onPlay={() => setIsPlaying(true)}
      />
      
      {/* Header */}
      <header className="bg-black bg-opacity-50 backdrop-blur-sm border-b border-white border-opacity-20">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-gradient-to-r from-pink-500 to-violet-500 rounded-full flex items-center justify-center">
                <span className="text-white text-xl font-bold">📻</span>
              </div>
              <div>
                <h1 className="text-3xl font-bold text-white">Global Radio</h1>
                <p className="text-gray-300 text-sm">Listen to radio stations worldwide</p>
              </div>
            </div>
            {currentStation && (
              <div className="hidden md:flex items-center space-x-4 text-white">
                <div className="text-right">
                  <p className="font-semibold">{currentStation.name}</p>
                  <p className="text-sm text-gray-300">{currentStation.country}</p>
                </div>
                <button
                  onClick={() => playStation(currentStation)}
                  className="w-12 h-12 bg-white bg-opacity-20 rounded-full flex items-center justify-center hover:bg-opacity-30 transition-all"
                >
                  <span className="text-2xl">{isPlaying ? '⏸️' : '▶️'}</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </header>

      {/* Controls */}
      <div className="max-w-7xl mx-auto px-4 py-6">
        <div className="bg-white bg-opacity-10 backdrop-blur-sm rounded-xl p-6 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
            <input
              type="text"
              placeholder="Search stations..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full px-4 py-2 rounded-lg bg-white bg-opacity-20 text-white placeholder-gray-300 focus:outline-none focus:ring-2 focus:ring-pink-500"
            />
            
            <select
              value={selectedCountry}
              onChange={(e) => setSelectedCountry(e.target.value)}
              className="w-full px-4 py-2 rounded-lg bg-white bg-opacity-20 text-white focus:outline-none focus:ring-2 focus:ring-pink-500"
            >
              <option value="">All Countries</option>
              {countries.map((country) => (
                <option key={country.name} value={country.name} className="text-black">
                  {country.name} ({country.stationcount})
                </option>
              ))}
            </select>

            <select
              value={selectedGenre}
              onChange={(e) => setSelectedGenre(e.target.value)}
              className="w-full px-4 py-2 rounded-lg bg-white bg-opacity-20 text-white focus:outline-none focus:ring-2 focus:ring-pink-500"
            >
              <option value="">All Genres</option>
              {genres.map((genre) => (
                <option key={genre.name} value={genre.name} className="text-black">
                  {genre.name} ({genre.stationcount})
                </option>
              ))}
            </select>

            <div className="flex space-x-2">
              <button
                onClick={searchStations}
                className="flex-1 bg-gradient-to-r from-pink-500 to-violet-500 text-white px-4 py-2 rounded-lg hover:from-pink-600 hover:to-violet-600 transition-all font-medium"
              >
                Search
              </button>
              <button
                onClick={clearFilters}
                className="px-4 py-2 bg-white bg-opacity-20 text-white rounded-lg hover:bg-opacity-30 transition-all"
              >
                Clear
              </button>
            </div>
          </div>

          {error && (
            <div className="bg-red-500 bg-opacity-20 border border-red-500 text-red-200 px-4 py-2 rounded-lg mb-4">
              {error}
            </div>
          )}
        </div>

        {/* Current Playing Station */}
        {currentStation && (
          <div className="bg-white bg-opacity-10 backdrop-blur-sm rounded-xl p-6 mb-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <div className="w-16 h-16 bg-gradient-to-r from-pink-500 to-violet-500 rounded-lg flex items-center justify-center">
                  <span className="text-white text-2xl">📻</span>
                </div>
                <div>
                  <h3 className="text-xl font-bold text-white">{currentStation.name}</h3>
                  <p className="text-gray-300">{currentStation.country} • {currentStation.tags}</p>
                  <p className="text-sm text-gray-400">
                    {currentStation.bitrate ? `${currentStation.bitrate} kbps` : ''} 
                    {currentStation.codec ? ` • ${currentStation.codec.toUpperCase()}` : ''}
                  </p>
                </div>
              </div>
              <button
                onClick={() => playStation(currentStation)}
                className="w-16 h-16 bg-white bg-opacity-20 rounded-full flex items-center justify-center hover:bg-opacity-30 transition-all"
              >
                <span className="text-3xl">{isPlaying ? '⏸️' : '▶️'}</span>
              </button>
            </div>
          </div>
        )}

        {/* Stations Grid */}
        {loading ? (
          <div className="text-center py-12">
            <div className="inline-block w-8 h-8 border-4 border-white border-opacity-30 border-t-white rounded-full animate-spin"></div>
            <p className="text-white mt-4">Loading stations...</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {stations.map((station) => (
              <div
                key={station.stationuuid}
                className={`bg-white bg-opacity-10 backdrop-blur-sm rounded-lg p-4 hover:bg-opacity-20 transition-all cursor-pointer border-2 ${
                  currentStation && currentStation.stationuuid === station.stationuuid
                    ? 'border-pink-500'
                    : 'border-transparent'
                }`}
                onClick={() => playStation(station)}
              >
                <div className="flex items-center justify-between mb-3">
                  <div className="w-10 h-10 bg-gradient-to-r from-pink-500 to-violet-500 rounded-lg flex items-center justify-center">
                    <span className="text-white text-lg">📻</span>
                  </div>
                  <span className="text-2xl">
                    {currentStation && currentStation.stationuuid === station.stationuuid && isPlaying ? '⏸️' : '▶️'}
                  </span>
                </div>
                <h3 className="text-white font-bold text-lg mb-1 truncate">{station.name}</h3>
                <p className="text-gray-300 text-sm mb-1">{station.country}</p>
                <p className="text-gray-400 text-xs truncate">{station.tags || 'Various genres'}</p>
                <div className="flex justify-between items-center mt-3 text-xs text-gray-400">
                  <span>{station.votes || 0} ♥</span>
                  <span>{station.bitrate ? `${station.bitrate}kbps` : ''}</span>
                </div>
              </div>
            ))}
          </div>
        )}

        {stations.length === 0 && !loading && (
          <div className="text-center py-12">
            <p className="text-white text-xl">No stations found</p>
            <p className="text-gray-300 mt-2">Try adjusting your search criteria</p>
          </div>
        )}
      </div>

      {/* Footer */}
      <footer className="bg-black bg-opacity-50 backdrop-blur-sm border-t border-white border-opacity-20 mt-12">
        <div className="max-w-7xl mx-auto px-4 py-6 text-center">
          <p className="text-gray-300">
            Powered by{' '}
            <a 
              href="https://www.radio-browser.info" 
              target="_blank" 
              rel="noopener noreferrer"
              className="text-pink-400 hover:text-pink-300"
            >
              Radio Browser
            </a>
            {' '}• Discover radio stations from around the world
          </p>
        </div>
      </footer>
    </div>
  );
}

export default App;