import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'core/api/graphql_client.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

class SSPNFCConfiguratorApp extends ConsumerWidget {
  const SSPNFCConfiguratorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final graphqlClient = ref.watch(graphqlClientProvider);

    return GraphQLProvider(
      client: graphqlClient,
      child: MaterialApp.router(
        title: 'SSP NFC Configurator',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
