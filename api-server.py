from flask import Flask
from flask_restplus import Api, Resource
from python_terraform import *
import re


app = Flask(__name__)
api = Api(app)

terraform_file_path=sys.argv[1]
print(terraform_file_path)
t = Terraform(working_dir=terraform_file_path)
t.init()


@api.route('/apply')
class TFPlan(Resource):
    def get(self):
        
        print('applying terraform configuration...')

        # force apply
        option_dict = dict()
        option_dict['auto-approve']=IsFlagged

        return_code, stdout, stderr = t.apply(  **option_dict)
        if not stderr:
            print(stdout)
            apply_output = parse_apply(stdout)
            return {'apply':apply_output }
        else:
            print('*****ERROR*****')
            print(stderr)
            print('*****OUTPUT*****')
            print(stdout)
            return {'apply': return_code, 'error': stderr, 'output': stdout}


@api.route('/plan')
class TFPlan(Resource):
    def get(self):
        return_code, stdout, stderr = t.plan()
        if not stderr:
            print(stdout)
            plan_output = parse_plan(stdout)
            return {'plan':plan_output}
        else:
            print('*****ERROR*****')
            print(stderr)
            print('*****OUTPUT*****')
            print(stdout)
            return {'plan': return_code, 'error':stderr, 'output':stdout}


@api.route('/destroy')
class TFPlan(Resource):
    def get(self):
        
        print('destroying terraform configuration...')

        # WARNING FORCE DESTROY without confirmation
        option_dict = dict()
        option_dict['force'] = IsFlagged
        return_code, stdout, stderr = t.destroy(**option_dict)
        if not stderr:
            print(stdout)
            destroy_output = parse_destroy(stdout)
            return {'destroy': destroy_output}
        else:
            print('*****ERROR*****')
            print(stderr)
            print('*****OUTPUT*****')
            print(stdout)
            return {'destroy': return_code, 'error': stderr, 'output': stdout}


tf_plan_exclude_action_list_re = re.compile('^[ ]*([\+\-\~])[ ]+(create|delete|modify)')
tf_plan_diff_re = re.compile('^[ ]*([\+\-\~])[ ]+(.*)')

tf_apply_summary_re = re.compile('^(.*Apply complete.*)')
tf_destroy_summary_re = re.compile('^(.*Destroy complete.*)')

convert_diff_type = {
        '+': 'add',
        '~': 'update',
        '-': 'remove'}


def parse_plan(tf_output):
    output = []
    for line in tf_output.split('\n'):
        matches=tf_plan_exclude_action_list_re.match(line)
        if(matches):
            continue
        matches=tf_plan_diff_re.match(line)
        if(matches):
            o = '%s %s' % (convert_diff_type[matches.group(1)], matches.group(2))
            output.append(o)
    return output

def parse_apply(tf_output):
    output = ''
    for line in tf_output.split('\n'):
        matches = tf_apply_summary_re.match(line)
        if not matches:
            continue
        output = matches.group(1)
        break
    return output


def parse_destroy(tf_output):
    output = ''
    for line in tf_output.split('\n'):
        matches = tf_destroy_summary_re.match(line)
        if not matches:
            continue
        output =  matches.group(1)
        break
    return output

if __name__ == '__main__':
    app.run(host='0.0.0.0')