
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/core/cloud/model/error_response.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/dashboard/providers/dashboard_support_provider.dart';
import 'package:linksys_app/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:phonenumbers/phonenumbers.dart';

class DashboardSupportView extends ArgumentsConsumerStatefulView {
  const DashboardSupportView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardSupportView> createState() =>
      _DashboardSupportViewState();
}

class _DashboardSupportViewState extends ConsumerState<DashboardSupportView> {
  bool isLoading = false;
  final phoneNumberController =
      PhoneNumberEditingController.fromCountryCode('US');
  TextEditingController emailController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController subjectController = TextEditingController();
  final EmailValidator emailValidator = EmailValidator();
  bool enableSend = false;
  bool isValidEmail = false;
  bool isValidPhone = false;

  List<Map<String, dynamic>> ticketList = [];
  bool hasOpenTicket = false;
  bool showList = false;

  @override
  void initState() {
    super.initState();

    phoneNumberController.addListener(() {
      logger.d('phone number changed');
      _onInputChanged();
    });
    _fetchTickets();
  }

  @override
  void dispose() {
    super.dispose();

    phoneNumberController.dispose();
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    subjectController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            scrollable: true,
            backState: StyledBackState.none,
            title: 'Support',
            child: BuildConfig.cloudEnv == 'qa'
                ? showList
                    ? _buildTicketList()
                    : _buildTicketForm()
                : const Center(),
          );
  }

  Widget _buildTicketList() {
    return Column(
      children: [
        ...ticketList.map(
          (ticket) => Container(
            height: 80,
            child: ListTile(
              leading: const Icon(Icons.confirmation_number),
              title: AppText.bodyLarge(ticket['description']),
              subtitle: AppText.bodySmall(ticket['status']),
            ),
          ),
        ),
        const Spacer(),
        AppFilledButton(
          'Form',
          onTap: () {
            setState(() {
              showList = false;
            });
          },
        )
      ],
    );
  }

  Widget _buildTicketForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField.outline(
          headerText: getAppLocalizations(context).email,
          controller: emailController,
          onChanged: (text) {
            setState(() {
              isValidEmail = emailValidator.validate(text);
            });
            _onInputChanged();
          },
        ),
        const AppGap.regular(),
        AppTextField.outline(
          headerText: getAppLocalizations(context).first_name,
          controller: firstNameController,
          onChanged: (text) {
            _onInputChanged();
          },
        ),
        const AppGap.regular(),
        AppTextField.outline(
          headerText: getAppLocalizations(context).last_name,
          controller: lastNameController,
          onChanged: (text) {
            _onInputChanged();
          },
        ),
        const AppGap.regular(),
        PhoneNumberFormField(
          autovalidateMode: AutovalidateMode.always,
          controller: phoneNumberController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const AppGap.regular(),
        const AppText.bodyMedium('Subject'),
        const AppGap.small(),
        AppTextField.outline(
          maxLines: 5,
          controller: subjectController,
          onChanged: (text) {
            _onInputChanged();
          },
        ),
        const AppGap.regular(),
        const Spacer(),
        Row(
          children: [
            _sendButton(),
            const AppGap.small(),
            _downloadButton(),
            const AppGap.small(),
            AppFilledButton(
              'List',
              onTap: () {
                setState(() {
                  showList = true;
                });
              },
            )
          ],
        ),
      ],
    );
  }

  Future<void> _fetchTickets() {
    if (BuildConfig.cloudEnv != 'qa') {
      return Future.value();
    }
    setState(() {
      isLoading = true;
    });
    return ref.read(supportProvider.notifier).fetchTickets().then((tickets) {
      setState(() {
        ticketList = tickets;
      });
    }).whenComplete(() {
      setState(() {
        hasOpenTicket = ticketList.any((ticket) =>
            ticket['status'] != 'Resolved' &&
            ticket['status'] != 'Timeout' &&
            ticket['status'] != 'Failed');
        isLoading = false;
      });
    });
  }

  _sendButton() {
    return AppElevatedButton(
      'Send',
      onTap: enableSend
          ? () async {
              setState(() {
                isLoading = true;
              });
              await ref
                  .read(supportProvider.notifier)
                  .startCreateTicket(
                      email: emailController.text,
                      firstName: firstNameController.text,
                      lastName: lastNameController.text,
                      phoneRegionCode:
                          '+${phoneNumberController.country?.prefix}',
                      phoneNumber: phoneNumberController.nationalNumber,
                      subject: subjectController.text)
                  .then((_) => _fetchTickets())
                  .then((_) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(AppToastHelp.positiveToast(
                  context,
                  text: 'Upload seccess',
                ));
              }).onError((error, stackTrace) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(AppToastHelp.negativeToast(
                  context,
                  text: (error as ErrorResponse?)?.errorMessage ??
                      'Unknown Error',
                ));
              }).whenComplete(() {
                setState(() {
                  isLoading = false;
                });
              });
            }
          : null,
    );
  }

  _downloadButton() {
    return AppElevatedButton(
      'Download',
      onTap: () async {
        setState(() {
          isLoading = true;
        });
        await ref
            .read(supportProvider.notifier)
            .download(context)
            .whenComplete(() {
          setState(() {
            isLoading = false;
          });
        });
      },
    );
  }

  void _onInputChanged() {
    setState(() {
      final phoneNumber = phoneNumberController.value;
      enableSend = isValidEmail &&
          firstNameController.text.isNotEmpty &&
          lastNameController.text.isNotEmpty &&
          phoneNumber != null &&
          phoneNumber.isValid &&
          subjectController.text.isNotEmpty;
    });
  }
}
