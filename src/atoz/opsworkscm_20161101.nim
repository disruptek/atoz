
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS OpsWorks CM
## version: 2016-11-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS OpsWorks CM</fullname> <p>AWS OpsWorks for configuration management (CM) is a service that runs and manages configuration management servers. You can use AWS OpsWorks CM to create and manage AWS OpsWorks for Chef Automate and AWS OpsWorks for Puppet Enterprise servers, and add or remove nodes for the servers to manage.</p> <p> <b>Glossary of terms</b> </p> <ul> <li> <p> <b>Server</b>: A configuration management server that can be highly-available. The configuration management server runs on an Amazon Elastic Compute Cloud (EC2) instance, and may use various other AWS services, such as Amazon Relational Database Service (RDS) and Elastic Load Balancing. A server is a generic abstraction over the configuration manager that you want to use, much like Amazon RDS. In AWS OpsWorks CM, you do not start or stop servers. After you create servers, they continue to run until they are deleted.</p> </li> <li> <p> <b>Engine</b>: The engine is the specific configuration manager that you want to use. Valid values in this release include <code>ChefAutomate</code> and <code>Puppet</code>.</p> </li> <li> <p> <b>Backup</b>: This is an application-level backup of the data that the configuration manager stores. AWS OpsWorks CM creates an S3 bucket for backups when you launch the first server. A backup maintains a snapshot of a server's configuration-related attributes at the time the backup starts.</p> </li> <li> <p> <b>Events</b>: Events are always related to a server. Events are written during server creation, when health checks run, when backups are created, when system maintenance is performed, etc. When you delete a server, the server's events are also deleted.</p> </li> <li> <p> <b>Account attributes</b>: Every account has attributes that are assigned in the AWS OpsWorks CM database. These attributes store information about configuration limits (servers, backups, etc.) and your customer account. </p> </li> </ul> <p> <b>Endpoints</b> </p> <p>AWS OpsWorks CM supports the following endpoints, all HTTPS. You must connect to one of the following endpoints. Your servers can only be accessed or managed within the endpoint in which they are created.</p> <ul> <li> <p>opsworks-cm.us-east-1.amazonaws.com</p> </li> <li> <p>opsworks-cm.us-east-2.amazonaws.com</p> </li> <li> <p>opsworks-cm.us-west-1.amazonaws.com</p> </li> <li> <p>opsworks-cm.us-west-2.amazonaws.com</p> </li> <li> <p>opsworks-cm.ap-northeast-1.amazonaws.com</p> </li> <li> <p>opsworks-cm.ap-southeast-1.amazonaws.com</p> </li> <li> <p>opsworks-cm.ap-southeast-2.amazonaws.com</p> </li> <li> <p>opsworks-cm.eu-central-1.amazonaws.com</p> </li> <li> <p>opsworks-cm.eu-west-1.amazonaws.com</p> </li> </ul> <p> <b>Throttling limits</b> </p> <p>All API operations allow for five requests per second with a burst of 10 requests per second.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/opsworks-cm/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "opsworks-cm.ap-northeast-1.amazonaws.com", "ap-southeast-1": "opsworks-cm.ap-southeast-1.amazonaws.com",
                           "us-west-2": "opsworks-cm.us-west-2.amazonaws.com",
                           "eu-west-2": "opsworks-cm.eu-west-2.amazonaws.com", "ap-northeast-3": "opsworks-cm.ap-northeast-3.amazonaws.com", "eu-central-1": "opsworks-cm.eu-central-1.amazonaws.com",
                           "us-east-2": "opsworks-cm.us-east-2.amazonaws.com",
                           "us-east-1": "opsworks-cm.us-east-1.amazonaws.com", "cn-northwest-1": "opsworks-cm.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "opsworks-cm.ap-south-1.amazonaws.com", "eu-north-1": "opsworks-cm.eu-north-1.amazonaws.com", "ap-northeast-2": "opsworks-cm.ap-northeast-2.amazonaws.com",
                           "us-west-1": "opsworks-cm.us-west-1.amazonaws.com", "us-gov-east-1": "opsworks-cm.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "opsworks-cm.eu-west-3.amazonaws.com", "cn-north-1": "opsworks-cm.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "opsworks-cm.sa-east-1.amazonaws.com",
                           "eu-west-1": "opsworks-cm.eu-west-1.amazonaws.com", "us-gov-west-1": "opsworks-cm.us-gov-west-1.amazonaws.com", "ap-southeast-2": "opsworks-cm.ap-southeast-2.amazonaws.com", "ca-central-1": "opsworks-cm.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "opsworks-cm.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "opsworks-cm.ap-southeast-1.amazonaws.com",
      "us-west-2": "opsworks-cm.us-west-2.amazonaws.com",
      "eu-west-2": "opsworks-cm.eu-west-2.amazonaws.com",
      "ap-northeast-3": "opsworks-cm.ap-northeast-3.amazonaws.com",
      "eu-central-1": "opsworks-cm.eu-central-1.amazonaws.com",
      "us-east-2": "opsworks-cm.us-east-2.amazonaws.com",
      "us-east-1": "opsworks-cm.us-east-1.amazonaws.com",
      "cn-northwest-1": "opsworks-cm.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "opsworks-cm.ap-south-1.amazonaws.com",
      "eu-north-1": "opsworks-cm.eu-north-1.amazonaws.com",
      "ap-northeast-2": "opsworks-cm.ap-northeast-2.amazonaws.com",
      "us-west-1": "opsworks-cm.us-west-1.amazonaws.com",
      "us-gov-east-1": "opsworks-cm.us-gov-east-1.amazonaws.com",
      "eu-west-3": "opsworks-cm.eu-west-3.amazonaws.com",
      "cn-north-1": "opsworks-cm.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "opsworks-cm.sa-east-1.amazonaws.com",
      "eu-west-1": "opsworks-cm.eu-west-1.amazonaws.com",
      "us-gov-west-1": "opsworks-cm.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "opsworks-cm.ap-southeast-2.amazonaws.com",
      "ca-central-1": "opsworks-cm.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "opsworkscm"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateNode_602803 = ref object of OpenApiRestCall_602466
proc url_AssociateNode_602805(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateNode_602804(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Associates a new node with the server. For more information about how to disassociate a node, see <a>DisassociateNode</a>.</p> <p> On a Chef server: This command is an alternative to <code>knife bootstrap</code>.</p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>CHEF_ORGANIZATION</i>,Value=default" "Name=<i>CHEF_NODE_PUBLIC_KEY</i>,Value=<i>public-key-pem</i>"</code> </p> <p> On a Puppet server, this command is an alternative to the <code>puppet cert sign</code> command that signs a Puppet node CSR. </p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>PUPPET_NODE_CSR</i>,Value=<i>csr-pem</i>"</code> </p> <p> A node can can only be associated with servers that are in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. The AssociateNode API call can be integrated into Auto Scaling configurations, AWS Cloudformation templates, or the user data of a server's instance. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.AssociateNode"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_AssociateNode_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Associates a new node with the server. For more information about how to disassociate a node, see <a>DisassociateNode</a>.</p> <p> On a Chef server: This command is an alternative to <code>knife bootstrap</code>.</p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>CHEF_ORGANIZATION</i>,Value=default" "Name=<i>CHEF_NODE_PUBLIC_KEY</i>,Value=<i>public-key-pem</i>"</code> </p> <p> On a Puppet server, this command is an alternative to the <code>puppet cert sign</code> command that signs a Puppet node CSR. </p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>PUPPET_NODE_CSR</i>,Value=<i>csr-pem</i>"</code> </p> <p> A node can can only be associated with servers that are in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. The AssociateNode API call can be integrated into Auto Scaling configurations, AWS Cloudformation templates, or the user data of a server's instance. </p>
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_AssociateNode_602803; body: JsonNode): Recallable =
  ## associateNode
  ## <p> Associates a new node with the server. For more information about how to disassociate a node, see <a>DisassociateNode</a>.</p> <p> On a Chef server: This command is an alternative to <code>knife bootstrap</code>.</p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>CHEF_ORGANIZATION</i>,Value=default" "Name=<i>CHEF_NODE_PUBLIC_KEY</i>,Value=<i>public-key-pem</i>"</code> </p> <p> On a Puppet server, this command is an alternative to the <code>puppet cert sign</code> command that signs a Puppet node CSR. </p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>PUPPET_NODE_CSR</i>,Value=<i>csr-pem</i>"</code> </p> <p> A node can can only be associated with servers that are in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. The AssociateNode API call can be integrated into Auto Scaling configurations, AWS Cloudformation templates, or the user data of a server's instance. </p>
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var associateNode* = Call_AssociateNode_602803(name: "associateNode",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.AssociateNode",
    validator: validate_AssociateNode_602804, base: "/", url: url_AssociateNode_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackup_603072 = ref object of OpenApiRestCall_602466
proc url_CreateBackup_603074(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateBackup_603073(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Creates an application-level backup of a server. While the server is in the <code>BACKING_UP</code> state, the server cannot be changed, and no additional backup can be created. </p> <p> Backups can be created for servers in <code>RUNNING</code>, <code>HEALTHY</code>, and <code>UNHEALTHY</code> states. By default, you can create a maximum of 50 manual backups. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when the maximum number of manual backups is reached. An <code>InvalidStateException</code> is thrown when the server is not in any of the following states: RUNNING, HEALTHY, or UNHEALTHY. A <code>ResourceNotFoundException</code> is thrown when the server is not found. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.CreateBackup"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_CreateBackup_603072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Creates an application-level backup of a server. While the server is in the <code>BACKING_UP</code> state, the server cannot be changed, and no additional backup can be created. </p> <p> Backups can be created for servers in <code>RUNNING</code>, <code>HEALTHY</code>, and <code>UNHEALTHY</code> states. By default, you can create a maximum of 50 manual backups. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when the maximum number of manual backups is reached. An <code>InvalidStateException</code> is thrown when the server is not in any of the following states: RUNNING, HEALTHY, or UNHEALTHY. A <code>ResourceNotFoundException</code> is thrown when the server is not found. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_CreateBackup_603072; body: JsonNode): Recallable =
  ## createBackup
  ## <p> Creates an application-level backup of a server. While the server is in the <code>BACKING_UP</code> state, the server cannot be changed, and no additional backup can be created. </p> <p> Backups can be created for servers in <code>RUNNING</code>, <code>HEALTHY</code>, and <code>UNHEALTHY</code> states. By default, you can create a maximum of 50 manual backups. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when the maximum number of manual backups is reached. An <code>InvalidStateException</code> is thrown when the server is not in any of the following states: RUNNING, HEALTHY, or UNHEALTHY. A <code>ResourceNotFoundException</code> is thrown when the server is not found. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var createBackup* = Call_CreateBackup_603072(name: "createBackup",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.CreateBackup",
    validator: validate_CreateBackup_603073, base: "/", url: url_CreateBackup_603074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateServer_603087 = ref object of OpenApiRestCall_602466
proc url_CreateServer_603089(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateServer_603088(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Creates and immedately starts a new server. The server is ready to use when it is in the <code>HEALTHY</code> state. By default, you can create a maximum of 10 servers. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when you have created the maximum number of servers (10). A <code>ResourceAlreadyExistsException</code> is thrown when a server with the same name already exists in the account. A <code>ResourceNotFoundException</code> is thrown when you specify a backup ID that is not valid or is for a backup that does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p> <p> If you do not specify a security group by adding the <code>SecurityGroupIds</code> parameter, AWS OpsWorks creates a new security group. </p> <p> <i>Chef Automate:</i> The default security group opens the Chef server to the world on TCP port 443. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p> <i>Puppet Enterprise:</i> The default security group opens TCP ports 22, 443, 4433, 8140, 8142, 8143, and 8170. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p>By default, your server is accessible from any IP address. We recommend that you update your security group rules to allow access from known IP addresses and address ranges only. To edit security group rules, open Security Groups in the navigation pane of the EC2 management console. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.CreateServer"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_CreateServer_603087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Creates and immedately starts a new server. The server is ready to use when it is in the <code>HEALTHY</code> state. By default, you can create a maximum of 10 servers. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when you have created the maximum number of servers (10). A <code>ResourceAlreadyExistsException</code> is thrown when a server with the same name already exists in the account. A <code>ResourceNotFoundException</code> is thrown when you specify a backup ID that is not valid or is for a backup that does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p> <p> If you do not specify a security group by adding the <code>SecurityGroupIds</code> parameter, AWS OpsWorks creates a new security group. </p> <p> <i>Chef Automate:</i> The default security group opens the Chef server to the world on TCP port 443. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p> <i>Puppet Enterprise:</i> The default security group opens TCP ports 22, 443, 4433, 8140, 8142, 8143, and 8170. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p>By default, your server is accessible from any IP address. We recommend that you update your security group rules to allow access from known IP addresses and address ranges only. To edit security group rules, open Security Groups in the navigation pane of the EC2 management console. </p>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_CreateServer_603087; body: JsonNode): Recallable =
  ## createServer
  ## <p> Creates and immedately starts a new server. The server is ready to use when it is in the <code>HEALTHY</code> state. By default, you can create a maximum of 10 servers. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when you have created the maximum number of servers (10). A <code>ResourceAlreadyExistsException</code> is thrown when a server with the same name already exists in the account. A <code>ResourceNotFoundException</code> is thrown when you specify a backup ID that is not valid or is for a backup that does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p> <p> If you do not specify a security group by adding the <code>SecurityGroupIds</code> parameter, AWS OpsWorks creates a new security group. </p> <p> <i>Chef Automate:</i> The default security group opens the Chef server to the world on TCP port 443. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p> <i>Puppet Enterprise:</i> The default security group opens TCP ports 22, 443, 4433, 8140, 8142, 8143, and 8170. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p>By default, your server is accessible from any IP address. We recommend that you update your security group rules to allow access from known IP addresses and address ranges only. To edit security group rules, open Security Groups in the navigation pane of the EC2 management console. </p>
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var createServer* = Call_CreateServer_603087(name: "createServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.CreateServer",
    validator: validate_CreateServer_603088, base: "/", url: url_CreateServer_603089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackup_603102 = ref object of OpenApiRestCall_602466
proc url_DeleteBackup_603104(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteBackup_603103(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Deletes a backup. You can delete both manual and automated backups. This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a backup deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DeleteBackup"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_DeleteBackup_603102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes a backup. You can delete both manual and automated backups. This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a backup deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_DeleteBackup_603102; body: JsonNode): Recallable =
  ## deleteBackup
  ## <p> Deletes a backup. You can delete both manual and automated backups. This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a backup deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var deleteBackup* = Call_DeleteBackup_603102(name: "deleteBackup",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DeleteBackup",
    validator: validate_DeleteBackup_603103, base: "/", url: url_DeleteBackup_603104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServer_603117 = ref object of OpenApiRestCall_602466
proc url_DeleteServer_603119(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteServer_603118(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Deletes the server and the underlying AWS CloudFormation stacks (including the server's EC2 instance). When you run this command, the server state is updated to <code>DELETING</code>. After the server is deleted, it is no longer returned by <code>DescribeServer</code> requests. If the AWS CloudFormation stack cannot be deleted, the server cannot be deleted. </p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a server deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p> <p> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DeleteServer"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_DeleteServer_603117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes the server and the underlying AWS CloudFormation stacks (including the server's EC2 instance). When you run this command, the server state is updated to <code>DELETING</code>. After the server is deleted, it is no longer returned by <code>DescribeServer</code> requests. If the AWS CloudFormation stack cannot be deleted, the server cannot be deleted. </p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a server deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p> <p> </p>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_DeleteServer_603117; body: JsonNode): Recallable =
  ## deleteServer
  ## <p> Deletes the server and the underlying AWS CloudFormation stacks (including the server's EC2 instance). When you run this command, the server state is updated to <code>DELETING</code>. After the server is deleted, it is no longer returned by <code>DescribeServer</code> requests. If the AWS CloudFormation stack cannot be deleted, the server cannot be deleted. </p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a server deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p> <p> </p>
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var deleteServer* = Call_DeleteServer_603117(name: "deleteServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DeleteServer",
    validator: validate_DeleteServer_603118, base: "/", url: url_DeleteServer_603119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountAttributes_603132 = ref object of OpenApiRestCall_602466
proc url_DescribeAccountAttributes_603134(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAccountAttributes_603133(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Describes your OpsWorks-CM account attributes. </p> <p> This operation is synchronous. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeAccountAttributes"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_DescribeAccountAttributes_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Describes your OpsWorks-CM account attributes. </p> <p> This operation is synchronous. </p>
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_DescribeAccountAttributes_603132; body: JsonNode): Recallable =
  ## describeAccountAttributes
  ## <p> Describes your OpsWorks-CM account attributes. </p> <p> This operation is synchronous. </p>
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var describeAccountAttributes* = Call_DescribeAccountAttributes_603132(
    name: "describeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeAccountAttributes",
    validator: validate_DescribeAccountAttributes_603133, base: "/",
    url: url_DescribeAccountAttributes_603134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackups_603147 = ref object of OpenApiRestCall_602466
proc url_DescribeBackups_603149(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeBackups_603148(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p> Describes backups. The results are ordered by time, with newest backups first. If you do not specify a BackupId or ServerName, the command returns all backups. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeBackups"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_DescribeBackups_603147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Describes backups. The results are ordered by time, with newest backups first. If you do not specify a BackupId or ServerName, the command returns all backups. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_DescribeBackups_603147; body: JsonNode): Recallable =
  ## describeBackups
  ## <p> Describes backups. The results are ordered by time, with newest backups first. If you do not specify a BackupId or ServerName, the command returns all backups. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var describeBackups* = Call_DescribeBackups_603147(name: "describeBackups",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeBackups",
    validator: validate_DescribeBackups_603148, base: "/", url: url_DescribeBackups_603149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_603162 = ref object of OpenApiRestCall_602466
proc url_DescribeEvents_603164(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEvents_603163(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p> Describes events for a specified server. Results are ordered by time, with newest events first. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeEvents"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_DescribeEvents_603162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Describes events for a specified server. Results are ordered by time, with newest events first. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_DescribeEvents_603162; body: JsonNode): Recallable =
  ## describeEvents
  ## <p> Describes events for a specified server. Results are ordered by time, with newest events first. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var describeEvents* = Call_DescribeEvents_603162(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeEvents",
    validator: validate_DescribeEvents_603163, base: "/", url: url_DescribeEvents_603164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNodeAssociationStatus_603177 = ref object of OpenApiRestCall_602466
proc url_DescribeNodeAssociationStatus_603179(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeNodeAssociationStatus_603178(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Returns the current status of an existing association or disassociation request. </p> <p> A <code>ResourceNotFoundException</code> is thrown when no recent association or disassociation request with the specified token is found, or when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeNodeAssociationStatus"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_DescribeNodeAssociationStatus_603177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns the current status of an existing association or disassociation request. </p> <p> A <code>ResourceNotFoundException</code> is thrown when no recent association or disassociation request with the specified token is found, or when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_DescribeNodeAssociationStatus_603177; body: JsonNode): Recallable =
  ## describeNodeAssociationStatus
  ## <p> Returns the current status of an existing association or disassociation request. </p> <p> A <code>ResourceNotFoundException</code> is thrown when no recent association or disassociation request with the specified token is found, or when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var describeNodeAssociationStatus* = Call_DescribeNodeAssociationStatus_603177(
    name: "describeNodeAssociationStatus", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com", route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeNodeAssociationStatus",
    validator: validate_DescribeNodeAssociationStatus_603178, base: "/",
    url: url_DescribeNodeAssociationStatus_603179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServers_603192 = ref object of OpenApiRestCall_602466
proc url_DescribeServers_603194(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeServers_603193(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p> Lists all configuration management servers that are identified with your account. Only the stored results from Amazon DynamoDB are returned. AWS OpsWorks CM does not query other services. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeServers"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_DescribeServers_603192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Lists all configuration management servers that are identified with your account. Only the stored results from Amazon DynamoDB are returned. AWS OpsWorks CM does not query other services. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_DescribeServers_603192; body: JsonNode): Recallable =
  ## describeServers
  ## <p> Lists all configuration management servers that are identified with your account. Only the stored results from Amazon DynamoDB are returned. AWS OpsWorks CM does not query other services. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var describeServers* = Call_DescribeServers_603192(name: "describeServers",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeServers",
    validator: validate_DescribeServers_603193, base: "/", url: url_DescribeServers_603194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateNode_603207 = ref object of OpenApiRestCall_602466
proc url_DisassociateNode_603209(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateNode_603208(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> Disassociates a node from an AWS OpsWorks CM server, and removes the node from the server's managed nodes. After a node is disassociated, the node key pair is no longer valid for accessing the configuration manager's API. For more information about how to associate a node, see <a>AssociateNode</a>. </p> <p>A node can can only be disassociated from a server that is in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DisassociateNode"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_DisassociateNode_603207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Disassociates a node from an AWS OpsWorks CM server, and removes the node from the server's managed nodes. After a node is disassociated, the node key pair is no longer valid for accessing the configuration manager's API. For more information about how to associate a node, see <a>AssociateNode</a>. </p> <p>A node can can only be disassociated from a server that is in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_DisassociateNode_603207; body: JsonNode): Recallable =
  ## disassociateNode
  ## <p> Disassociates a node from an AWS OpsWorks CM server, and removes the node from the server's managed nodes. After a node is disassociated, the node key pair is no longer valid for accessing the configuration manager's API. For more information about how to associate a node, see <a>AssociateNode</a>. </p> <p>A node can can only be disassociated from a server that is in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var disassociateNode* = Call_DisassociateNode_603207(name: "disassociateNode",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DisassociateNode",
    validator: validate_DisassociateNode_603208, base: "/",
    url: url_DisassociateNode_603209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportServerEngineAttribute_603222 = ref object of OpenApiRestCall_602466
proc url_ExportServerEngineAttribute_603224(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ExportServerEngineAttribute_603223(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Exports a specified server engine attribute as a base64-encoded string. For example, you can export user data that you can use in EC2 to associate nodes with a server. </p> <p> This operation is synchronous. </p> <p> A <code>ValidationException</code> is raised when parameters of the request are not valid. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. An <code>InvalidStateException</code> is thrown when the server is in any of the following states: CREATING, TERMINATED, FAILED or DELETING. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.ExportServerEngineAttribute"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_ExportServerEngineAttribute_603222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Exports a specified server engine attribute as a base64-encoded string. For example, you can export user data that you can use in EC2 to associate nodes with a server. </p> <p> This operation is synchronous. </p> <p> A <code>ValidationException</code> is raised when parameters of the request are not valid. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. An <code>InvalidStateException</code> is thrown when the server is in any of the following states: CREATING, TERMINATED, FAILED or DELETING. </p>
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_ExportServerEngineAttribute_603222; body: JsonNode): Recallable =
  ## exportServerEngineAttribute
  ## <p> Exports a specified server engine attribute as a base64-encoded string. For example, you can export user data that you can use in EC2 to associate nodes with a server. </p> <p> This operation is synchronous. </p> <p> A <code>ValidationException</code> is raised when parameters of the request are not valid. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. An <code>InvalidStateException</code> is thrown when the server is in any of the following states: CREATING, TERMINATED, FAILED or DELETING. </p>
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var exportServerEngineAttribute* = Call_ExportServerEngineAttribute_603222(
    name: "exportServerEngineAttribute", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.ExportServerEngineAttribute",
    validator: validate_ExportServerEngineAttribute_603223, base: "/",
    url: url_ExportServerEngineAttribute_603224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreServer_603237 = ref object of OpenApiRestCall_602466
proc url_RestoreServer_603239(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RestoreServer_603238(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Restores a backup to a server that is in a <code>CONNECTION_LOST</code>, <code>HEALTHY</code>, <code>RUNNING</code>, <code>UNHEALTHY</code>, or <code>TERMINATED</code> state. When you run RestoreServer, the server's EC2 instance is deleted, and a new EC2 instance is configured. RestoreServer maintains the existing server endpoint, so configuration management of the server's client devices (nodes) should continue to work. </p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when the server is not in a valid state. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.RestoreServer"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_RestoreServer_603237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Restores a backup to a server that is in a <code>CONNECTION_LOST</code>, <code>HEALTHY</code>, <code>RUNNING</code>, <code>UNHEALTHY</code>, or <code>TERMINATED</code> state. When you run RestoreServer, the server's EC2 instance is deleted, and a new EC2 instance is configured. RestoreServer maintains the existing server endpoint, so configuration management of the server's client devices (nodes) should continue to work. </p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when the server is not in a valid state. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_RestoreServer_603237; body: JsonNode): Recallable =
  ## restoreServer
  ## <p> Restores a backup to a server that is in a <code>CONNECTION_LOST</code>, <code>HEALTHY</code>, <code>RUNNING</code>, <code>UNHEALTHY</code>, or <code>TERMINATED</code> state. When you run RestoreServer, the server's EC2 instance is deleted, and a new EC2 instance is configured. RestoreServer maintains the existing server endpoint, so configuration management of the server's client devices (nodes) should continue to work. </p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when the server is not in a valid state. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var restoreServer* = Call_RestoreServer_603237(name: "restoreServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.RestoreServer",
    validator: validate_RestoreServer_603238, base: "/", url: url_RestoreServer_603239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMaintenance_603252 = ref object of OpenApiRestCall_602466
proc url_StartMaintenance_603254(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartMaintenance_603253(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> Manually starts server maintenance. This command can be useful if an earlier maintenance attempt failed, and the underlying cause of maintenance failure has been resolved. The server is in an <code>UNDER_MAINTENANCE</code> state while maintenance is in progress. </p> <p> Maintenance can only be started on servers in <code>HEALTHY</code> and <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.StartMaintenance"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_StartMaintenance_603252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Manually starts server maintenance. This command can be useful if an earlier maintenance attempt failed, and the underlying cause of maintenance failure has been resolved. The server is in an <code>UNDER_MAINTENANCE</code> state while maintenance is in progress. </p> <p> Maintenance can only be started on servers in <code>HEALTHY</code> and <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_StartMaintenance_603252; body: JsonNode): Recallable =
  ## startMaintenance
  ## <p> Manually starts server maintenance. This command can be useful if an earlier maintenance attempt failed, and the underlying cause of maintenance failure has been resolved. The server is in an <code>UNDER_MAINTENANCE</code> state while maintenance is in progress. </p> <p> Maintenance can only be started on servers in <code>HEALTHY</code> and <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var startMaintenance* = Call_StartMaintenance_603252(name: "startMaintenance",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.StartMaintenance",
    validator: validate_StartMaintenance_603253, base: "/",
    url: url_StartMaintenance_603254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServer_603267 = ref object of OpenApiRestCall_602466
proc url_UpdateServer_603269(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateServer_603268(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Updates settings for a server. </p> <p> This operation is synchronous. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.UpdateServer"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_UpdateServer_603267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Updates settings for a server. </p> <p> This operation is synchronous. </p>
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_UpdateServer_603267; body: JsonNode): Recallable =
  ## updateServer
  ## <p> Updates settings for a server. </p> <p> This operation is synchronous. </p>
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var updateServer* = Call_UpdateServer_603267(name: "updateServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.UpdateServer",
    validator: validate_UpdateServer_603268, base: "/", url: url_UpdateServer_603269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServerEngineAttributes_603282 = ref object of OpenApiRestCall_602466
proc url_UpdateServerEngineAttributes_603284(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateServerEngineAttributes_603283(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Updates engine-specific attributes on a specified server. The server enters the <code>MODIFYING</code> state when this operation is in progress. Only one update can occur at a time. You can use this command to reset a Chef server's public key (<code>CHEF_PIVOTAL_KEY</code>) or a Puppet server's admin password (<code>PUPPET_ADMIN_PASSWORD</code>). </p> <p> This operation is asynchronous. </p> <p> This operation can only be called for servers in <code>HEALTHY</code> or <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is raised. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.UpdateServerEngineAttributes"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_UpdateServerEngineAttributes_603282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Updates engine-specific attributes on a specified server. The server enters the <code>MODIFYING</code> state when this operation is in progress. Only one update can occur at a time. You can use this command to reset a Chef server's public key (<code>CHEF_PIVOTAL_KEY</code>) or a Puppet server's admin password (<code>PUPPET_ADMIN_PASSWORD</code>). </p> <p> This operation is asynchronous. </p> <p> This operation can only be called for servers in <code>HEALTHY</code> or <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is raised. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_UpdateServerEngineAttributes_603282; body: JsonNode): Recallable =
  ## updateServerEngineAttributes
  ## <p> Updates engine-specific attributes on a specified server. The server enters the <code>MODIFYING</code> state when this operation is in progress. Only one update can occur at a time. You can use this command to reset a Chef server's public key (<code>CHEF_PIVOTAL_KEY</code>) or a Puppet server's admin password (<code>PUPPET_ADMIN_PASSWORD</code>). </p> <p> This operation is asynchronous. </p> <p> This operation can only be called for servers in <code>HEALTHY</code> or <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is raised. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_603296 = newJObject()
  if body != nil:
    body_603296 = body
  result = call_603295.call(nil, nil, nil, nil, body_603296)

var updateServerEngineAttributes* = Call_UpdateServerEngineAttributes_603282(
    name: "updateServerEngineAttributes", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com", route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.UpdateServerEngineAttributes",
    validator: validate_UpdateServerEngineAttributes_603283, base: "/",
    url: url_UpdateServerEngineAttributes_603284,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
