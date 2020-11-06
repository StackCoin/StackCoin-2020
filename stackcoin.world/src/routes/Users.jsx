import React from 'react'
import { useQuery } from 'urql';
import { Box, Flex } from "@chakra-ui/core";

import User from '../components/User';

function Users() {
	const [res] = useQuery({
		query: `
			query {
				user(order_by: {id: asc}) {
					username
					id
					avatar_url
				}
			}
		`,
	});

	if (res.fetching) return <p>Loading...</p>;
	if (res.error) return <p>Errored!</p>;

	return (
		<Flex align="center" flexDir="column">
			{
				res.data.user.map((user) => (
					<Box mt={5}>
						<User key={user.id} username={user.username} />
					</Box>
				))
			}
		</Flex>
	)
}

export default Users;
