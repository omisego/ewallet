import _ from 'lodash'
import createReducer from '../reducer/createReducer'
export const accessKeysReducer = createReducer(
  {},
  {
    'ACCESS_KEY/CREATE/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.id]: data } }
    },
    'ACCESS_KEY/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.id]: data } }
    },
    'ACCESS_KEYS/REQUEST/SUCCESS': (state, { data }) => {
      return _.merge(state, _.keyBy(data, 'id'))
    },
    'MEMBERSHIP_ACCESS_KEYS/REQUEST/SUCCESS': (state, { data }) => {
      return _.merge(state, _.keyBy(data, 'key.id'))
    },
    'ACCESS_KEY/UPDATE/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.id]: data } }
    },
    'CURRENT_ACCOUNT/SWITCH': () => ({})
  }
)

export const accessKeyLoadingStatusReducer = createReducer('DEFAULT', {
  'ACCESS_KEYS/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
