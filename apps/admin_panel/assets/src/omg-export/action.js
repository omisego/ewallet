import * as exportService from '../services/exportService'
import CONSTANT from '../constants'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const getExport = id => {
  return createActionCreator({
    actionName: 'EXPORT',
    action: 'REQUEST',
    service: () => exportService.getExportFileById(id)
  })
}

export const getExports = ({ page, perPage, matchAll, matchAny, cacheKey }) => {
  return createPaginationActionCreator({
    actionName: 'EXPORTS',
    action: 'REQUEST',
    service: () =>
      exportService.getExportFiles({
        page,
        perPage,
        matchAll,
        matchAny,
        sortBy: 'created_at',
        sortDir: 'desc'
      }),
    cacheKey
  })
}

export const downloadExportFileById = file => async dispatch => {
  const dispatchError = error => {
    console.error('failed to dispatch action EXPORT/DOWNLOAD', 'with error', error)
    return dispatch({
      type: `EXPORT/DOWNLOAD/${CONSTANT.LOADING_STATUS.FAILED}`,
      error: error
    })
  }
  try {
    const result = await exportService.downloadExportFileById(file.id)
    if (result.data) {
      if (file.adapter === 'local') {
        const csvData = new window.Blob([result.data], { type: 'text/csv;charset=utf-8;' })
        const csvURL = window.URL.createObjectURL(csvData)
        const tempLink = document.createElement('a')
        tempLink.href = csvURL
        tempLink.setAttribute('download', `${file.filename}.csv`)
        tempLink.click()
      }
      if (file.adapter === 'gcs' || file.adapter === 'aws') {
        const result = await exportService.getExportFileById(file.id)
        if (result.data.success) {
          window.location.href = result.data.data.download_url
        } else {
          return dispatch({
            type: `EXPORT/DOWNLOAD/${CONSTANT.LOADING_STATUS.FAILED}`,
            error: `Failed to fetch file ${file.id}`
          })
        }
      }
      return dispatch({
        type: `EXPORT/DOWNLOAD/${CONSTANT.LOADING_STATUS.SUCCESS}`,
        data: result.data
      })
    } else {
      return dispatch({
        type: `EXPORT/DOWNLOAD/${CONSTANT.LOADING_STATUS.FAILED}`
      })
    }
  } catch (error) {
    dispatchError(error)
  }
}