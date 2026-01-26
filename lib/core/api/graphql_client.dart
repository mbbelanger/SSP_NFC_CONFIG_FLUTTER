import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

final graphqlClientProvider = Provider<ValueNotifier<GraphQLClient>>((ref) {
  final httpLink = HttpLink(ApiConstants.graphqlEndpoint);

  final authLink = AuthLink(
    getToken: () async {
      final token = await SecureStorage.getToken();
      return token != null ? 'Bearer $token' : null;
    },
  );

  final link = authLink.concat(httpLink);

  return ValueNotifier(
    GraphQLClient(
      link: link,
      cache: GraphQLCache(store: HiveStore()),
    ),
  );
});

// Provider for raw GraphQL client (for use outside of widgets)
final graphqlRawClientProvider = Provider<GraphQLClient>((ref) {
  final clientNotifier = ref.watch(graphqlClientProvider);
  return clientNotifier.value;
});
