import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { Image } from 'react-bootstrap';
import PropTypes from 'prop-types';
import SidebarLink from './SidebarLink';

import logo from '../../../public/images/dummy_sidebar_logo.png';

const Sidebar = ({ translate, currentPath }) => (
  <div className="sidebar fh">
    <div className="col-xs-10 col-xs-offset-1">
      <Image className="sidebar__logo" src={logo} />
      <h2 className="sidebar__title">Minor International</h2>
      <ul className="sidebar__ul">
        <li className="sidebar__li">
          <SidebarLink to="/" title={translate('sidebar.dashboard')} currentPath={currentPath} />
        </li>
        <li className="sidebar__li">
          <SidebarLink
            to="/accounts"
            title={translate('sidebar.accounts')}
            currentPath={currentPath}
          />
        </li>
        <li className="sidebar__li">
          <SidebarLink to="/" title={translate('sidebar.transactions')} currentPath={currentPath} />
        </li>
        <li className="sidebar__li">
          <SidebarLink to="/" title={translate('sidebar.tokens')} currentPath={currentPath} />
        </li>
        <li className="sidebar__li">
          <SidebarLink to="/" title={translate('sidebar.reports')} currentPath={currentPath} />
        </li>
        <li className="sidebar__li">
          <SidebarLink
            to="/"
            title={translate('sidebar.api_management')}
            currentPath={currentPath}
          />
        </li>
        <li className="sidebar__li">
          <SidebarLink to="/" title={translate('sidebar.setting')} currentPath={currentPath} />
        </li>
      </ul>
    </div>
  </div>
);

Sidebar.propTypes = {
  translate: PropTypes.func.isRequired,
  currentPath: PropTypes.string.isRequired,
};

function mapStateToProps(state) {
  const translate = getTranslate(state.locale);
  const currentPath = state.router.location.pathname;
  return {
    translate,
    currentPath,
  };
}

export default withRouter(connect(mapStateToProps)(Sidebar));
