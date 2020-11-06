import React from 'react'
import { Box, Text } from "@chakra-ui/core";

function User({ username }) {
	return (
		<Box maxW="sm" borderWidth="1px" rounded="lg" overflow="hidden">
			<Text m={0}>{username}</Text>
		</Box>
	);
}

export default User;
