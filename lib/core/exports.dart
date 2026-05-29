// lib/core/exports.dart
// هذا الملف يجمع جميع الـ Imports الأساسية

// Flutter
import 'package:flutter/material.dart';

// Core Constants & Theme
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/theme/app_theme.dart';

// Core Services
import 'package:app/core/services/bonus_calculator.dart';
import 'package:app/core/services/balance_calculator.dart';
import 'package:app/core/services/cart_calculator.dart';
import 'package:app/core/services/currency_converter.dart';
import 'package:app/core/services/sales_calculator.dart';
import 'package:app/core/services/statistics_calculator.dart';
import 'package:app/core/services/debouncer.dart';
import 'package:app/core/services/snackbar_service.dart';
import 'package:app/core/services/cache_service.dart';

// Core Widgets
import 'package:app/core/widgets/cached_image.dart';
import 'package:app/core/widgets/loading_overlay.dart';
import 'package:app/core/widgets/state_widgets.dart';
import 'package:app/core/widgets/quantity_selector.dart';
import 'package:app/core/widgets/enhanced_product_card.dart';

// Core Extensions & Utils
import 'package:app/core/extensions/num_extensions.dart';
import 'package:app/core/utils/category_utils.dart';
import 'package:app/core/utils/date_utils.dart';
import 'package:app/core/utils/product_helper.dart';
import 'package:app/core/utils/order_helper.dart';
import 'package:app/core/utils/company_helper.dart';
import 'package:app/core/utils/report_helper.dart';

// Data Models
import 'package:app/data/datasources/models/account_model.dart';
import 'package:app/data/datasources/models/order_model.dart';
import 'package:app/data/datasources/models/product_model.dart';
import 'package:app/data/datasources/models/cart_item.dart';

// Reports Models
import 'package:app/modules/reports/models/report_models.dart';