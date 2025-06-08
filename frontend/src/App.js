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
  const [favorites, setFavorites] = useState([]);
  const [favoritesLoaded, setFavoritesLoaded] = useState(false);
  const [showFavorites, setShowFavorites] = useState(false);
  const [searchTimeout, setSearchTimeout] = useState(null);
  const [darkMode, setDarkMode] = useState(() => {
    // Initialize dark mode from localStorage synchronously
    try {
      const savedDarkMode = localStorage.getItem('globalRadioDarkMode');
      return savedDarkMode ? JSON.parse(savedDarkMode) : false;
    } catch (error) {
      console.error('Error loading initial dark mode:', error);
      return false;
    }
  });
  const audioRef = useRef(null);

  // Apply dark mode class on initial load and changes
  useEffect(() => {
    try {
      localStorage.setItem('globalRadioDarkMode', JSON.stringify(darkMode));
      console.log('Dark mode saved to localStorage:', darkMode);
      
      // Apply dark mode class to document
      if (darkMode) {
        document.documentElement.classList.add('dark');
        document.body.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
        document.body.classList.remove('dark');
      }
    } catch (error) {
      console.error('Error saving dark mode preference:', error);
    }
  }, [darkMode]);

  const toggleDarkMode = () => {
    setDarkMode(!darkMode);
  };

  // Helper function to check if text needs scrolling
  const needsScrolling = (text, maxLength = 30) => {
    return text && text.length > maxLength;
  };

  // Helper function to create scrolling text component
  const ScrollingText = ({ text, className = "", maxLength = 30 }) => {
    const shouldScroll = needsScrolling(text, maxLength);
    
    return (
      <div className={`text-container ${shouldScroll ? 'scrollable' : ''}`}>
        <span className={`${className} ${shouldScroll ? 'long-text' : ''}`}>
          {text}
        </span>
      </div>
    );
  };

  // Load favorites from localStorage on component mount
  useEffect(() => {
    const loadFavorites = () => {
      try {
        const savedFavorites = localStorage.getItem('globalRadioFavorites');
        console.log('Loading favorites from localStorage:', savedFavorites);
        
        if (savedFavorites && savedFavorites !== 'undefined' && savedFavorites !== 'null') {
          const parsedFavorites = JSON.parse(savedFavorites);
          console.log('Parsed favorites:', parsedFavorites);
          
          if (Array.isArray(parsedFavorites)) {
            setFavorites(parsedFavorites);
            console.log('Favorites loaded successfully:', parsedFavorites.length, 'stations');
          } else {
            console.warn('Invalid favorites format, resetting to empty array');
            setFavorites([]);
          }
        } else {
          console.log('No saved favorites found, starting with empty array');
          setFavorites([]);
        }
      } catch (error) {
        console.error('Error loading favorites from localStorage:', error);
        setFavorites([]);
        // Clear corrupted data
        localStorage.removeItem('globalRadioFavorites');
      } finally {
        setFavoritesLoaded(true);
      }
    };

    loadFavorites();
  }, []);

  // Save favorites to localStorage whenever favorites change (but only after initial load)
  useEffect(() => {
    if (favoritesLoaded) {
      console.log('Saving favorites to localStorage:', favorites.length, 'stations');
      localStorage.setItem('globalRadioFavorites', JSON.stringify(favorites));
      console.log('Favorites saved successfully');
    }
  }, [favorites, favoritesLoaded]);

  // Fetch initial data
  useEffect(() => {
    fetchPopularStations();
    fetchCountries();
  }, []);

  const fetchPopularStations = async () => {
    try {
      setLoading(true);
      setError('');
      
      const response = await fetch(`${API}/radio/stations/popular?limit=100`);
      
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
      console.error('Error fetching stations:', err);
      setError('Unable to load radio stations. Please try again.');
    } finally {
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

  const playStation = async (station) => {
    try {
      if (currentStation && currentStation.stationuuid === station.stationuuid && isPlaying) {
        audioRef.current.pause();
        setIsPlaying(false);
        return;
      }

      console.log('Playing station:', station.name, 'URL:', station.url_resolved || station.url);

      // Always set the current station first for UI update
      setCurrentStation(station);
      setError(''); // Clear any previous errors
      
      // Register click with our backend
      try {
        await fetch(`${API}/radio/stations/${station.stationuuid}/click`, {
          method: 'POST'
        });
      } catch (e) {
        // Ignore click registration errors
        console.log('Click registration failed (non-critical):', e);
      }

      // Set the audio source
      const audioUrl = station.url_resolved || station.url;
      console.log('Setting audio source to:', audioUrl);
      audioRef.current.src = audioUrl;
      
      try {
        console.log('Attempting to play audio...');
        await audioRef.current.play();
        setIsPlaying(true);
        console.log('Audio started playing successfully');
      } catch (playError) {
        console.error('Audio playback error:', playError);
        setError(`Cannot play "${station.name}". This station may be offline or blocked by browser.`);
        setIsPlaying(false);
        // DON'T clear the currentStation so we can still see the UI
        console.log('Audio failed but keeping station selected for UI testing');
      }
    } catch (err) {
      console.error('Error in playStation function:', err);
      setError('Playback failed. Please try another station.');
      // Still keep the station selected for UI purposes
      setCurrentStation(station);
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
    setShowFavorites(false);
    clearTimeout(searchTimeout);
    fetchPopularStations();
  };

  const performSearch = async (searchValue = searchTerm, countryValue = selectedCountry) => {
    // Don't search if we're showing favorites
    if (showFavorites) return;
    
    // If both search and country are empty, show popular stations
    if (!searchValue.trim() && !countryValue) {
      fetchPopularStations();
      return;
    }

    try {
      setLoading(true);
      setError('');
      
      let url = `${API}/radio/stations/search?limit=100`;
      
      if (searchValue.trim()) {
        url += `&name=${encodeURIComponent(searchValue.trim())}`;
      }
      if (countryValue) {
        url += `&country=${encodeURIComponent(countryValue)}`;
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

  const handleSearchChange = (value) => {
    setSearchTerm(value);
    
    // Clear existing timeout
    if (searchTimeout) {
      clearTimeout(searchTimeout);
    }
    
    // Set new timeout for debounced search
    const newTimeout = setTimeout(() => {
      performSearch(value, selectedCountry);
    }, 300); // 300ms delay
    
    setSearchTimeout(newTimeout);
  };

  const handleCountryChange = (value) => {
    setSelectedCountry(value);
    // Clear any pending search timeout since country change should be immediate
    if (searchTimeout) {
      clearTimeout(searchTimeout);
    }
    // Perform immediate search with new country
    performSearch(searchTerm, value);
  };

  const toggleFavorite = (station) => {
    console.log('toggleFavorite called with station:', station.name);
    setFavorites(prevFavorites => {
      console.log('Current favorites before toggle:', prevFavorites.length);
      const isAlreadyFavorite = prevFavorites.some(fav => fav.stationuuid === station.stationuuid);
      console.log('Is already favorite:', isAlreadyFavorite);
      
      if (isAlreadyFavorite) {
        // Remove from favorites
        console.log('Removing from favorites:', station.name);
        const newFavorites = prevFavorites.filter(fav => fav.stationuuid !== station.stationuuid);
        console.log('New favorites count after removal:', newFavorites.length);
        return newFavorites;
      } else {
        // Add to favorites
        console.log('Adding to favorites:', station.name);
        const newFavorites = [...prevFavorites, station];
        console.log('New favorites count after addition:', newFavorites.length);
        return newFavorites;
      }
    });
  };

  const isFavorite = (station) => {
    return favorites.some(fav => fav.stationuuid === station.stationuuid);
  };

  const showFavoriteStations = () => {
    setShowFavorites(true);
    setStations(favorites);
    setLoading(false);
  };

  const clearAllFavorites = () => {
    setFavorites([]);
    localStorage.removeItem('globalRadioFavorites');
    console.log('All favorites cleared');
  };

  const displayedStations = showFavorites ? favorites : stations;

  return (
    <div className={`min-h-screen transition-colors duration-300 ${darkMode ? 'bg-gray-900' : 'bg-white'}`}>
      <audio 
        ref={audioRef} 
        onError={handleAudioError}
        onEnded={() => setIsPlaying(false)}
        onPause={() => setIsPlaying(false)}
        onPlay={() => setIsPlaying(true)}
        crossOrigin="anonymous"
      />
      
      {/* Header */}
      <header className={`border-b sticky top-0 z-10 shadow-sm transition-colors duration-300 ${
        darkMode 
          ? 'border-gray-700 bg-gray-900' 
          : 'border-gray-200 bg-white'
      }`}>
        <div className="max-w-6xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center transition-colors duration-300 ${
                darkMode ? 'bg-white' : 'bg-black'
              }`}>
                <span className={`text-sm font-bold ${darkMode ? 'text-black' : 'text-white'}`}>R</span>
              </div>
              <div>
                <h1 className={`text-2xl font-light transition-colors duration-300 ${
                  darkMode ? 'text-white' : 'text-black'
                }`}>Global Radio</h1>
                <p className={`text-sm transition-colors duration-300 ${
                  darkMode ? 'text-gray-400' : 'text-gray-500'
                }`}>Worldwide stations</p>
              </div>
            </div>

            <div className="flex items-center space-x-4">
              {/* Dark Mode Toggle */}
              <button
                onClick={toggleDarkMode}
                className={`w-10 h-10 rounded-full flex items-center justify-center transition-all duration-300 ${
                  darkMode 
                    ? 'bg-gray-700 text-yellow-400 hover:bg-gray-600' 
                    : 'bg-gray-200 text-gray-600 hover:bg-gray-300'
                }`}
                title={darkMode ? 'Switch to light mode' : 'Switch to dark mode'}
              >
                {darkMode ? '☀️' : '🌙'}
              </button>

              {/* Floating Current Playing - Fixed Width with Scrolling */}
              {currentStation && (
                <div className={`flex items-center space-x-3 rounded-lg px-3 py-2 shadow-md player-controls transition-colors duration-300 ${
                  darkMode ? 'bg-gray-800 text-white' : 'bg-black text-white'
                }`}>
                  <div className="flex items-center space-x-2 flex-1 min-w-0">
                    <div className="w-5 h-5 bg-white bg-opacity-20 rounded-full flex items-center justify-center flex-shrink-0">
                      <span className="text-xs">📻</span>
                    </div>
                    <div className="station-info flex-1 min-w-0">
                      <div className="station-name">
                        <ScrollingText 
                          text={currentStation.name} 
                          className="text-xs md:text-sm font-medium"
                          maxLength={15}
                        />
                      </div>
                      <div className="text-container">
                        <span className="text-gray-300 text-xs truncate">{currentStation.country}</span>
                      </div>
                    </div>
                    {isPlaying && (
                      <div className="flex items-center text-xs text-gray-300 ml-1 flex-shrink-0">
                        <div className="w-1.5 h-1.5 bg-red-500 rounded-full animate-pulse mr-1"></div>
                        <span className="hidden sm:inline text-xs">LIVE</span>
                      </div>
                    )}
                  </div>
                  <div className="flex space-x-1 ml-1 flex-shrink-0">
                    <button
                      onClick={() => playStation(currentStation)}
                      className="w-6 h-6 md:w-7 md:h-7 bg-white text-black rounded-full flex items-center justify-center hover:bg-gray-200 transition-colors text-xs"
                      title={isPlaying ? 'Pause' : 'Play'}
                    >
                      {isPlaying ? '⏸' : '▶'}
                    </button>
                    <button
                      onClick={stopPlayback}
                      className={`w-6 h-6 md:w-7 md:h-7 rounded-full flex items-center justify-center transition-colors text-xs ${
                        darkMode ? 'bg-gray-600 text-white hover:bg-gray-500' : 'bg-gray-700 text-white hover:bg-gray-600'
                      }`}
                      title="Stop"
                    >
                      ⏹
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </header>

      {/* Search Controls */}
      <div className="max-w-6xl mx-auto px-4 py-6">
        {/* Favorites and Search Toggle */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex space-x-4">
            <button
              onClick={() => {
                setShowFavorites(false);
                if (stations.length === 0 || showFavorites) {
                  fetchPopularStations();
                }
              }}
              className={`px-4 py-2 rounded-lg font-medium transition-colors duration-300 ${
                !showFavorites 
                  ? darkMode ? 'bg-white text-black' : 'bg-black text-white'
                  : darkMode ? 'bg-gray-700 text-gray-300 hover:bg-gray-600' : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              }`}
            >
              All Stations
            </button>
            <button
              onClick={showFavoriteStations}
              className={`px-4 py-2 rounded-lg font-medium transition-colors duration-300 ${
                showFavorites 
                  ? darkMode ? 'bg-white text-black' : 'bg-black text-white'
                  : darkMode ? 'bg-gray-700 text-gray-300 hover:bg-gray-600' : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              }`}
            >
              ❤️ Favorites ({favorites.length})
            </button>
          </div>
        </div>

        {!showFavorites && (
          <div className={`rounded-lg p-6 mb-6 transition-colors duration-300 ${
            darkMode ? 'bg-gray-800' : 'bg-gray-50'
          }`}>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
              <input
                type="text"
                placeholder="Search stations..."
                value={searchTerm}
                onChange={(e) => handleSearchChange(e.target.value)}
                className={`w-full px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-black focus:border-transparent transition-colors duration-300 ${
                  darkMode 
                    ? 'border-gray-600 bg-gray-700 text-white placeholder-gray-400' 
                    : 'border-gray-300 bg-white text-black placeholder-gray-500'
                }`}
              />
              
              <select
                value={selectedCountry}
                onChange={(e) => handleCountryChange(e.target.value)}
                className={`w-full px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-black focus:border-transparent transition-colors duration-300 ${
                  darkMode 
                    ? 'border-gray-600 bg-gray-700 text-white' 
                    : 'border-gray-300 bg-white text-black'
                }`}
              >
                <option value="">All Countries</option>
                {countries.map((country) => (
                  <option key={country.name} value={country.name}>
                    {country.name} ({country.stationcount})
                  </option>
                ))}
              </select>

              <div className="flex justify-end">
                <button
                  type="button"
                  onClick={resetToPopular}
                  className={`px-6 py-3 border rounded-lg font-medium transition-colors duration-300 ${
                    darkMode 
                      ? 'border-gray-600 text-gray-300 hover:bg-gray-700' 
                      : 'border-gray-300 text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  Clear Filters
                </button>
              </div>
            </div>

            {error && (
              <div className={`border px-4 py-3 rounded-lg transition-colors duration-300 ${
                darkMode 
                  ? 'bg-red-900 border-red-700 text-red-200' 
                  : 'bg-red-50 border-red-200 text-red-700'
              }`}>
                {error}
              </div>
            )}

            {/* Real-time search indicator */}
            {(searchTerm || selectedCountry) && !loading && (
              <div className={`text-sm mt-2 transition-colors duration-300 ${
                darkMode ? 'text-gray-400' : 'text-gray-600'
              }`}>
                {searchTerm && selectedCountry 
                  ? `Filtering by "${searchTerm}" in ${selectedCountry}`
                  : searchTerm 
                    ? `Searching for "${searchTerm}"`
                    : `Showing stations from ${selectedCountry}`
                }
                {stations.length > 0 && ` • ${stations.length} station${stations.length !== 1 ? 's' : ''} found`}
              </div>
            )}
          </div>
        )}

        {showFavorites && (
          <div className={`border rounded-lg p-6 mb-6 transition-colors duration-300 ${
            darkMode 
              ? 'bg-pink-900 border-pink-700' 
              : 'bg-pink-50 border-pink-200'
          }`}>
            <div className="flex items-center justify-between">
              <div>
                <h3 className={`text-lg font-medium transition-colors duration-300 ${
                  darkMode ? 'text-pink-200' : 'text-pink-900'
                }`}>Your Favorite Stations</h3>
                <p className={`text-sm mt-1 transition-colors duration-300 ${
                  darkMode ? 'text-pink-300' : 'text-pink-700'
                }`}>
                  {favorites.length === 0 
                    ? "You haven't added any favorite stations yet. Click the ❤️ icon on any station to add it to your favorites!"
                    : `You have ${favorites.length} favorite station${favorites.length !== 1 ? 's' : ''}`
                  }
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Loading State */}
        {loading && (
          <div className="text-center py-12">
            <div className={`inline-block w-6 h-6 border-2 rounded-full animate-spin transition-colors duration-300 ${
              darkMode ? 'border-gray-600 border-t-white' : 'border-gray-300 border-t-black'
            }`}></div>
            <p className={`mt-4 transition-colors duration-300 ${
              darkMode ? 'text-gray-400' : 'text-gray-600'
            }`}>Loading stations...</p>
          </div>
        )}

        {/* Stations Grid */}
        {!loading && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {displayedStations.map((station) => (
              <div
                key={station.stationuuid}
                className={`border rounded-lg p-4 hover:shadow-md transition-all cursor-pointer relative duration-300 ${
                  currentStation && currentStation.stationuuid === station.stationuuid
                    ? darkMode ? 'border-white bg-gray-800' : 'border-black bg-gray-50'
                    : darkMode ? 'border-gray-600 hover:border-gray-500 bg-gray-800' : 'border-gray-200 hover:border-gray-300 bg-white'
                }`}
              >
                {/* Favorite Button */}
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    toggleFavorite(station);
                  }}
                  className={`absolute top-3 right-3 w-8 h-8 rounded-full flex items-center justify-center transition-all duration-300 ${
                    isFavorite(station)
                      ? darkMode ? 'bg-pink-900 text-pink-400 hover:bg-pink-800' : 'bg-pink-100 text-pink-600 hover:bg-pink-200'
                      : darkMode ? 'bg-gray-700 text-gray-500 hover:bg-gray-600 hover:text-pink-400' : 'bg-gray-100 text-gray-400 hover:bg-gray-200 hover:text-pink-500'
                  }`}
                  title={isFavorite(station) ? 'Remove from favorites' : 'Add to favorites'}
                >
                  {isFavorite(station) ? '❤️' : '🤍'}
                </button>

                <div 
                  onClick={() => playStation(station)}
                  className="pr-10"
                >
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1 min-w-0">
                      <h3 className={`font-medium truncate transition-colors duration-300 ${
                        darkMode ? 'text-white' : 'text-gray-900'
                      }`}>{station.name}</h3>
                      <p className={`text-sm transition-colors duration-300 ${
                        darkMode ? 'text-gray-400' : 'text-gray-600'
                      }`}>{station.country}</p>
                    </div>
                    <button className={`ml-3 text-xl transition-colors duration-300 ${
                      darkMode ? 'text-gray-500 hover:text-white' : 'text-gray-400 hover:text-black'
                    }`}>
                      {currentStation && currentStation.stationuuid === station.stationuuid && isPlaying ? '⏸' : '▶'}
                    </button>
                  </div>
                  
                  {station.tags && (
                    <p className={`text-xs mb-2 truncate transition-colors duration-300 ${
                      darkMode ? 'text-gray-500' : 'text-gray-500'
                    }`}>{station.tags}</p>
                  )}
                  
                  <div className={`flex justify-between items-center text-xs transition-colors duration-300 ${
                    darkMode ? 'text-gray-500' : 'text-gray-400'
                  }`}>
                    <span>{station.votes || 0} votes</span>
                    {station.bitrate && <span>{station.bitrate} kbps</span>}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Empty State */}
        {!loading && displayedStations.length === 0 && (
          <div className="text-center py-12">
            <p className={`text-xl font-light transition-colors duration-300 ${
              darkMode ? 'text-white' : 'text-gray-900'
            }`}>
              {showFavorites ? 'No favorite stations yet' : 'No stations found'}
            </p>
            <p className={`mt-2 transition-colors duration-300 ${
              darkMode ? 'text-gray-400' : 'text-gray-500'
            }`}>
              {showFavorites 
                ? 'Add stations to your favorites by clicking the ❤️ icon on any station card'
                : 'Try adjusting your search criteria'
              }
            </p>
          </div>
        )}
      </div>

      {/* Footer */}
      <footer className={`border-t mt-12 transition-colors duration-300 ${
        darkMode ? 'border-gray-700 bg-gray-800' : 'border-gray-200 bg-gray-50'
      }`}>
        <div className="max-w-6xl mx-auto px-4 py-6 text-center">
          <p className={`text-sm transition-colors duration-300 ${
            darkMode ? 'text-gray-400' : 'text-gray-500'
          }`}>
            Worldwide radio streaming
          </p>
        </div>
      </footer>
    </div>
  );
}

export default App;