import { BrowserRouter as Router, Redirect, Switch } from 'react-router-dom'
import React from 'react'

import AuthenticatedRoute from './authenticatedRoute'
import LoginRoute from './loginRoute'
import LoginForm from '../../omg-login-form'
import ForgetPasswordForm from '../../omg-forgetPassword-form'
import CreateNewPasswordForm from '../../omg-createNewPassword-form'
import AccountPage from '../../omg-page-account'
import DashboardPage from '../../omg-page-dashboard'
import TokenPage from '../../omg-page-token'
import TransactionPage from '../../omg-page-transaction'
import BalancePage from '../../omg-page-balance'
import AccountDetailPage from '../../omg-page-account-detail'
import AccountSettingPage from '../../omg-page-account-setting'
import UserSettingPage from '../../omg-page-user-setting'
import ApiKeyPage from '../../omg-page-api'
import UserPage from '../../omg-page-users'
import TokenDetailPage from '../../omg-page-token-detail'
import { getCurrentAccountFromLocalStorage } from '../../services/sessionService'
const currentAccount = getCurrentAccountFromLocalStorage()
const redirectUrl = currentAccount ? `${currentAccount.id}/dashboard` : '/login'
export default () => (
  <Router basename='/admin/'>
    <Switch>
      <Redirect from='/' to={redirectUrl} exact />
      <LoginRoute path='/login' exact component={LoginForm} />
      <LoginRoute path='/forget-password' exact component={ForgetPasswordForm} />
      <LoginRoute path='/create-new-password' exact component={CreateNewPasswordForm} />
      <AuthenticatedRoute path='/:accountId/dashboard' exact component={DashboardPage} />
      <AuthenticatedRoute path='/:accountId/accounts' exact component={AccountPage} />\
      <AuthenticatedRoute path='/:accountId/token' exact component={TokenPage} />
      <AuthenticatedRoute path='/:accountId/token/:viewTokenId' exact component={TokenDetailPage} />
      <AuthenticatedRoute path='/:accountId/wallets' exact component={BalancePage} />
      <AuthenticatedRoute path='/:accountId/transaction' exact component={TransactionPage} />
      <AuthenticatedRoute path='/:accountId/api' exact component={ApiKeyPage} />
      <AuthenticatedRoute path='/:accountId/setting' exact component={AccountSettingPage} />
      <AuthenticatedRoute path='/:accountId/user_setting' exact component={UserSettingPage} />
      <AuthenticatedRoute path='/:accountId/customer' exact component={UserPage} />
      <AuthenticatedRoute path='/:accountId/account/:viewAccountId' exact component={AccountDetailPage} />

    </Switch>
  </Router>
)
