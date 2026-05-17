import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/dashboard/command_center_screen.dart';
import '../../features/inventory/inventory_qr_scan_screen.dart';
import '../../features/inventory/inventory_list_screen.dart';
import '../../features/inventory/inventory_detail_screen.dart';
import '../../features/inventory/add_inventory_screen.dart';
import '../../features/inventory/log_transaction_screen.dart';
import '../../features/machines/machine_list_screen.dart';
import '../../features/machines/machine_detail_screen.dart';
import '../../features/cylinders/cylinder_list_screen.dart';
import '../../features/work_orders/work_order_list_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/leave/leave_application_screen.dart';
import '../../features/payroll/payroll_list_screen.dart';
import '../../features/clients/client_list_screen.dart';
import '../../features/reports/reports_hub_screen.dart';
import '../../features/alerts/alerts_screen.dart';
import '../../features/settings/settings_hub_screen.dart';
import '../../features/settings/edit_user_screen.dart';
import '../../features/settings/backup_restore_screen.dart';
import '../../features/ai_chat/forgeops_chat_screen.dart';
import '../../features/shell/main_shell.dart';
import '../providers/session_provider.dart';
// ── Phase 2: Order Control System ─────────────────────────────────
import '../../features/orders/order_list_screen.dart';
import '../../features/orders/add_order_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/voice_order_screen.dart';
// ── Phase 5: Calendar ─────────────────────────────────────────────
import '../../features/calendar/calendar_screen.dart';

class AppRouter {
  static GoRouter createRouter(SessionProvider sessionProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: sessionProvider,
      redirect: (context, state) {
        final isLoggedIn = sessionProvider.isLoggedIn;
        final isLoginRoute = state.matchedLocation == '/login';
        final isRegisterRoute = state.matchedLocation == '/register';
        if (!isLoggedIn && !isLoginRoute && !isRegisterRoute) return '/login';
        if (isLoggedIn && (isLoginRoute || isRegisterRoute)) return '/dashboard';
        return null;
      },
      // Safety net: any routing error (e.g. during logout transition)
      // shows the login screen instead of a crash page or blank screen.
      errorBuilder: (context, state) => const LoginScreen(),
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (ctx, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (ctx, state) => const RegisterScreen(),
        ),
        ShellRoute(
          builder: (ctx, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (ctx, state) => const CommandCenterScreen(),
            ),
            GoRoute(
              path: '/inventory',
              name: 'inventory',
              builder: (ctx, state) => const InventoryListScreen(),
              routes: [
                GoRoute(
                  path: 'qr-scan',
                  name: 'inventory-qr-scan',
                  builder: (ctx, state) => const InventoryQrScanScreen(),
                ),
                GoRoute(
                  path: 'detail/:id',
                  name: 'inventory-detail',
                  builder: (ctx, state) => InventoryDetailScreen(
                    itemId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'add',
                  name: 'inventory-add',
                  builder: (ctx, state) => const AddInventoryScreen(),
                ),
                GoRoute(
                  path: 'log-transaction',
                  name: 'inventory-log',
                  builder: (ctx, state) => const LogTransactionScreen(),
                ),
                GoRoute(
                  path: 'receive-stock',
                  name: 'inventory-receive',
                  builder: (ctx, state) => const ReceiveStockScreen(),
                ),
              ],
            ),
            GoRoute(
              path: '/machines',
              name: 'machines',
              builder: (ctx, state) => const MachineListScreen(),
              routes: [
                GoRoute(
                  path: 'detail/:id',
                  name: 'machine-detail',
                  builder: (ctx, state) => MachineDetailScreen(
                    machineId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'analytics/:id',
                  name: 'machine-analytics',
                  builder: (ctx, state) => MachineAnalyticsScreen(
                    machineId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/cylinders',
              name: 'cylinders',
              builder: (ctx, state) => const CylinderListScreen(),
              routes: [
                GoRoute(
                  path: 'detail/:id',
                  name: 'cylinder-detail',
                  builder: (ctx, state) => CylinderDetailScreen(
                    cylinderId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'qr-scan',
                  name: 'cylinder-qr-scan',
                  builder: (ctx, state) => const CylinderQrScanScreen(),
                ),
                GoRoute(
                  path: 'scan-success/:id',
                  name: 'cylinder-scan-success',
                  builder: (ctx, state) => CylinderScanSuccessScreen(
                    cylinderId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/work-orders',
              name: 'work-orders',
              builder: (ctx, state) => const WorkOrderListScreen(),
              routes: [
                GoRoute(
                  path: 'kanban',
                  name: 'work-order-kanban',
                  builder: (ctx, state) => const WorkOrderKanbanScreen(),
                ),
                GoRoute(
                  path: 'detail/:id',
                  name: 'work-order-detail',
                  builder: (ctx, state) => WorkOrderDetailScreen(
                    workOrderId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'create',
                  name: 'work-order-create',
                  builder: (ctx, state) => const CreateWorkOrderScreen(),
                ),
              ],
            ),
            GoRoute(
              path: '/attendance',
              name: 'attendance',
              builder: (ctx, state) => const AttendanceScreen(),
              routes: [
                GoRoute(
                  path: 'qr-checkin',
                  name: 'qr-checkin',
                  builder: (ctx, state) => const QrCheckinScreen(),
                ),
                GoRoute(
                  path: 'supervisor-approval',
                  name: 'supervisor-approval',
                  builder: (ctx, state) => const SupervisorApprovalScreen(),
                ),
              ],
            ),
            GoRoute(
              path: '/leave',
              name: 'leave',
              builder: (ctx, state) => const LeaveApplicationScreen(),
              routes: [
                GoRoute(
                  path: 'approval-queue',
                  name: 'leave-approval-queue',
                  builder: (ctx, state) => const LeaveApprovalQueueScreen(),
                ),
              ],
            ),
            GoRoute(
              path: '/payroll',
              name: 'payroll',
              builder: (ctx, state) => const PayrollListScreen(),
              routes: [
                GoRoute(
                  path: 'payslip/:id',
                  name: 'payslip',
                  builder: (ctx, state) => PayslipPreviewScreen(
                    payslipId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/clients',
              name: 'clients',
              builder: (ctx, state) => const ClientListScreen(),
              routes: [
                GoRoute(
                  path: 'detail/:id',
                  name: 'client-detail',
                  builder: (ctx, state) => ClientDetailScreen(
                    clientId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'create-order',
                  name: 'create-order',
                  builder: (ctx, state) => const CreateOrderScreen(),
                ),
                GoRoute(
                  path: 'invoice/:id',
                  name: 'invoice',
                  builder: (ctx, state) => InvoicePreviewScreen(
                    clientId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/reports',
              name: 'reports',
              builder: (ctx, state) => const ReportsHubScreen(),
              routes: [
                GoRoute(
                  path: 'attendance',
                  name: 'attendance-report',
                  builder: (ctx, state) => const AttendanceReportScreen(),
                ),
                GoRoute(
                  path: 'inventory',
                  name: 'inventory-report',
                  builder: (ctx, state) => const InventoryReportScreen(),
                ),
                GoRoute(
                  path: 'production',
                  name: 'production-report',
                  builder: (ctx, state) => const ProductionReportScreen(),
                ),
                GoRoute(
                  path: 'financial',
                  name: 'financial-report',
                  builder: (ctx, state) => const FinancialReportScreen(),
                ),
                GoRoute(
                  path: 'work-orders',
                  name: 'work-order-report',
                  builder: (ctx, state) => const WorkOrderReportScreen(),
                ),
              ],
            ),
            // ── Order Control System ───────────────────────────────────────
            GoRoute(
              path: '/orders',
              name: 'orders',
              builder: (ctx, state) => const OrderListScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'order-add',
                  builder: (ctx, state) {
                    final clientId = state.uri.queryParameters['clientId'];
                    final clientName = state.uri.queryParameters['clientName'];
                    return AddOrderScreen(
                      preselectedClientId: clientId,
                      preselectedClientName: clientName,
                    );
                  },
                ),
                GoRoute(
                  path: 'detail/:id',
                  name: 'order-detail',
                  builder: (ctx, state) => OrderDetailScreen(
                    orderId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'voice',
                  name: 'order-voice',
                  builder: (ctx, state) => const VoiceOrderScreen(),
                ),
              ],
            ),
            // ── Calendar Timeline ─────────────────────────────────────────
            GoRoute(
              path: '/calendar',
              name: 'calendar',
              builder: (ctx, state) => const CalendarScreen(),
            ),
            GoRoute(
              path: '/alerts',
              name: 'alerts',
              builder: (ctx, state) => const AlertsScreen(),
            ),
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (ctx, state) => const SettingsHubScreen(),
              routes: [
                GoRoute(
                  path: 'company-profile',
                  name: 'company-profile',
                  builder: (ctx, state) => const CompanyProfileScreen(),
                ),
                GoRoute(
                  path: 'user-management',
                  name: 'user-management',
                  builder: (ctx, state) => const UserManagementScreen(),
                ),
                GoRoute(
                  path: 'edit-user/:id',
                  name: 'edit-user',
                  builder: (ctx, state) => EditUserScreen(
                    user: const <String, dynamic>{},
                  ),
                ),
                GoRoute(
                  path: 'role-permissions',
                  name: 'role-permissions',
                  builder: (ctx, state) => const RolePermissionsScreen(),
                ),
                GoRoute(
                  path: 'shift-templates',
                  name: 'shift-templates',
                  builder: (ctx, state) => const ShiftTemplatesScreen(),
                ),
                GoRoute(
                  path: 'system-config',
                  name: 'system-config',
                  builder: (ctx, state) => const SystemConfigScreen(),
                ),
                GoRoute(
                  path: 'backup-restore',
                  name: 'backup-restore',
                  builder: (ctx, state) => const BackupRestoreScreen(),
                ),
                GoRoute(
                  path: 'developer-tools',
                  name: 'developer-tools',
                  builder: (ctx, state) => const DeveloperToolsScreen(),
                ),
              ],
            ),
            GoRoute(
              path: '/ai-chat',
              name: 'ai-chat',
              builder: (ctx, state) => const ForgeOpsChatScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
