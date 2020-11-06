import React from 'react'
import { createClient, Provider } from 'urql';
import { ThemeProvider } from "@chakra-ui/core";

import Routes from './Routes';

const client = createClient({ url: '/v1/graphql/' });

function App() {
	return (
		<ThemeProvider>
			<Provider value={client}>
				<Routes />
			</Provider>
		</ThemeProvider>
	);
}

export default App;
