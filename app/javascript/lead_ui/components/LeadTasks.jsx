import React from 'react'
import Style from './LeadTasks.scss'
import LeadRow from './LeadRow'

class LeadTasks extends React.Component {

  taskItem(task) {
    if (task === undefined) {
      return('')
    }

    return(
      <div key={task.id} className={"row " + Style.TaskItem}>
        <div className="col-md-1">
          &check;
        </div>
        <div className="col-md-11">
          <span className="TaskDateTime">
            {task.start_time}
          </span>
        </div>
      </div>
    )
  }

  render() {
    const taskItems = ( this.props.lead.tasks || [] ).map((t) => this.taskItem(t))
    return(
      <div className={Style.LeadTasks}>
        <LeadRow add=''>
          <div className="col-md-12">
            <b>Tasks</b>
              {taskItems}
          </div>
        </LeadRow>
      </div>
    )
  }
}

export default LeadTasks
