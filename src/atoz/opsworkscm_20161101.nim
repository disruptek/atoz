
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateNode_605927 = ref object of OpenApiRestCall_605589
proc url_AssociateNode_605929(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateNode_605928(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.AssociateNode"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_AssociateNode_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Associates a new node with the server. For more information about how to disassociate a node, see <a>DisassociateNode</a>.</p> <p> On a Chef server: This command is an alternative to <code>knife bootstrap</code>.</p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>CHEF_ORGANIZATION</i>,Value=default" "Name=<i>CHEF_NODE_PUBLIC_KEY</i>,Value=<i>public-key-pem</i>"</code> </p> <p> On a Puppet server, this command is an alternative to the <code>puppet cert sign</code> command that signs a Puppet node CSR. </p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>PUPPET_NODE_CSR</i>,Value=<i>csr-pem</i>"</code> </p> <p> A node can can only be associated with servers that are in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. The AssociateNode API call can be integrated into Auto Scaling configurations, AWS Cloudformation templates, or the user data of a server's instance. </p>
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_AssociateNode_605927; body: JsonNode): Recallable =
  ## associateNode
  ## <p> Associates a new node with the server. For more information about how to disassociate a node, see <a>DisassociateNode</a>.</p> <p> On a Chef server: This command is an alternative to <code>knife bootstrap</code>.</p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>CHEF_ORGANIZATION</i>,Value=default" "Name=<i>CHEF_NODE_PUBLIC_KEY</i>,Value=<i>public-key-pem</i>"</code> </p> <p> On a Puppet server, this command is an alternative to the <code>puppet cert sign</code> command that signs a Puppet node CSR. </p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>PUPPET_NODE_CSR</i>,Value=<i>csr-pem</i>"</code> </p> <p> A node can can only be associated with servers that are in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. The AssociateNode API call can be integrated into Auto Scaling configurations, AWS Cloudformation templates, or the user data of a server's instance. </p>
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var associateNode* = Call_AssociateNode_605927(name: "associateNode",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.AssociateNode",
    validator: validate_AssociateNode_605928, base: "/", url: url_AssociateNode_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackup_606196 = ref object of OpenApiRestCall_605589
proc url_CreateBackup_606198(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBackup_606197(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.CreateBackup"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_CreateBackup_606196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Creates an application-level backup of a server. While the server is in the <code>BACKING_UP</code> state, the server cannot be changed, and no additional backup can be created. </p> <p> Backups can be created for servers in <code>RUNNING</code>, <code>HEALTHY</code>, and <code>UNHEALTHY</code> states. By default, you can create a maximum of 50 manual backups. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when the maximum number of manual backups is reached. An <code>InvalidStateException</code> is thrown when the server is not in any of the following states: RUNNING, HEALTHY, or UNHEALTHY. A <code>ResourceNotFoundException</code> is thrown when the server is not found. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_CreateBackup_606196; body: JsonNode): Recallable =
  ## createBackup
  ## <p> Creates an application-level backup of a server. While the server is in the <code>BACKING_UP</code> state, the server cannot be changed, and no additional backup can be created. </p> <p> Backups can be created for servers in <code>RUNNING</code>, <code>HEALTHY</code>, and <code>UNHEALTHY</code> states. By default, you can create a maximum of 50 manual backups. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when the maximum number of manual backups is reached. An <code>InvalidStateException</code> is thrown when the server is not in any of the following states: RUNNING, HEALTHY, or UNHEALTHY. A <code>ResourceNotFoundException</code> is thrown when the server is not found. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var createBackup* = Call_CreateBackup_606196(name: "createBackup",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.CreateBackup",
    validator: validate_CreateBackup_606197, base: "/", url: url_CreateBackup_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateServer_606211 = ref object of OpenApiRestCall_605589
proc url_CreateServer_606213(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateServer_606212(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Creates and immedately starts a new server. The server is ready to use when it is in the <code>HEALTHY</code> state. By default, you can create a maximum of 10 servers. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when you have created the maximum number of servers (10). A <code>ResourceAlreadyExistsException</code> is thrown when a server with the same name already exists in the account. A <code>ResourceNotFoundException</code> is thrown when you specify a backup ID that is not valid or is for a backup that does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p> <p> If you do not specify a security group by adding the <code>SecurityGroupIds</code> parameter, AWS OpsWorks creates a new security group. </p> <p> <i>Chef Automate:</i> The default security group opens the Chef server to the world on TCP port 443. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p> <i>Puppet Enterprise:</i> The default security group opens TCP ports 22, 443, 4433, 8140, 8142, 8143, and 8170. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p>By default, your server is accessible from any IP address. We recommend that you update your security group rules to allow access from known IP addresses and address ranges only. To edit security group rules, open Security Groups in the navigation pane of the EC2 management console. </p> <p>To specify your own domain for a server, and provide your own self-signed or CA-signed certificate and private key, specify values for <code>CustomDomain</code>, <code>CustomCertificate</code>, and <code>CustomPrivateKey</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.CreateServer"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_CreateServer_606211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Creates and immedately starts a new server. The server is ready to use when it is in the <code>HEALTHY</code> state. By default, you can create a maximum of 10 servers. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when you have created the maximum number of servers (10). A <code>ResourceAlreadyExistsException</code> is thrown when a server with the same name already exists in the account. A <code>ResourceNotFoundException</code> is thrown when you specify a backup ID that is not valid or is for a backup that does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p> <p> If you do not specify a security group by adding the <code>SecurityGroupIds</code> parameter, AWS OpsWorks creates a new security group. </p> <p> <i>Chef Automate:</i> The default security group opens the Chef server to the world on TCP port 443. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p> <i>Puppet Enterprise:</i> The default security group opens TCP ports 22, 443, 4433, 8140, 8142, 8143, and 8170. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p>By default, your server is accessible from any IP address. We recommend that you update your security group rules to allow access from known IP addresses and address ranges only. To edit security group rules, open Security Groups in the navigation pane of the EC2 management console. </p> <p>To specify your own domain for a server, and provide your own self-signed or CA-signed certificate and private key, specify values for <code>CustomDomain</code>, <code>CustomCertificate</code>, and <code>CustomPrivateKey</code>.</p>
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_CreateServer_606211; body: JsonNode): Recallable =
  ## createServer
  ## <p> Creates and immedately starts a new server. The server is ready to use when it is in the <code>HEALTHY</code> state. By default, you can create a maximum of 10 servers. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when you have created the maximum number of servers (10). A <code>ResourceAlreadyExistsException</code> is thrown when a server with the same name already exists in the account. A <code>ResourceNotFoundException</code> is thrown when you specify a backup ID that is not valid or is for a backup that does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p> <p> If you do not specify a security group by adding the <code>SecurityGroupIds</code> parameter, AWS OpsWorks creates a new security group. </p> <p> <i>Chef Automate:</i> The default security group opens the Chef server to the world on TCP port 443. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p> <i>Puppet Enterprise:</i> The default security group opens TCP ports 22, 443, 4433, 8140, 8142, 8143, and 8170. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p>By default, your server is accessible from any IP address. We recommend that you update your security group rules to allow access from known IP addresses and address ranges only. To edit security group rules, open Security Groups in the navigation pane of the EC2 management console. </p> <p>To specify your own domain for a server, and provide your own self-signed or CA-signed certificate and private key, specify values for <code>CustomDomain</code>, <code>CustomCertificate</code>, and <code>CustomPrivateKey</code>.</p>
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var createServer* = Call_CreateServer_606211(name: "createServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.CreateServer",
    validator: validate_CreateServer_606212, base: "/", url: url_CreateServer_606213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackup_606226 = ref object of OpenApiRestCall_605589
proc url_DeleteBackup_606228(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBackup_606227(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DeleteBackup"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_DeleteBackup_606226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes a backup. You can delete both manual and automated backups. This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a backup deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_DeleteBackup_606226; body: JsonNode): Recallable =
  ## deleteBackup
  ## <p> Deletes a backup. You can delete both manual and automated backups. This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a backup deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var deleteBackup* = Call_DeleteBackup_606226(name: "deleteBackup",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DeleteBackup",
    validator: validate_DeleteBackup_606227, base: "/", url: url_DeleteBackup_606228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServer_606241 = ref object of OpenApiRestCall_605589
proc url_DeleteServer_606243(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteServer_606242(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DeleteServer"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_DeleteServer_606241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes the server and the underlying AWS CloudFormation stacks (including the server's EC2 instance). When you run this command, the server state is updated to <code>DELETING</code>. After the server is deleted, it is no longer returned by <code>DescribeServer</code> requests. If the AWS CloudFormation stack cannot be deleted, the server cannot be deleted. </p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a server deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p> <p> </p>
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_DeleteServer_606241; body: JsonNode): Recallable =
  ## deleteServer
  ## <p> Deletes the server and the underlying AWS CloudFormation stacks (including the server's EC2 instance). When you run this command, the server state is updated to <code>DELETING</code>. After the server is deleted, it is no longer returned by <code>DescribeServer</code> requests. If the AWS CloudFormation stack cannot be deleted, the server cannot be deleted. </p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a server deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p> <p> </p>
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var deleteServer* = Call_DeleteServer_606241(name: "deleteServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DeleteServer",
    validator: validate_DeleteServer_606242, base: "/", url: url_DeleteServer_606243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountAttributes_606256 = ref object of OpenApiRestCall_605589
proc url_DescribeAccountAttributes_606258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAccountAttributes_606257(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeAccountAttributes"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_DescribeAccountAttributes_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Describes your OpsWorks-CM account attributes. </p> <p> This operation is synchronous. </p>
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_DescribeAccountAttributes_606256; body: JsonNode): Recallable =
  ## describeAccountAttributes
  ## <p> Describes your OpsWorks-CM account attributes. </p> <p> This operation is synchronous. </p>
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var describeAccountAttributes* = Call_DescribeAccountAttributes_606256(
    name: "describeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeAccountAttributes",
    validator: validate_DescribeAccountAttributes_606257, base: "/",
    url: url_DescribeAccountAttributes_606258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackups_606271 = ref object of OpenApiRestCall_605589
proc url_DescribeBackups_606273(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBackups_606272(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeBackups"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_DescribeBackups_606271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Describes backups. The results are ordered by time, with newest backups first. If you do not specify a BackupId or ServerName, the command returns all backups. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_DescribeBackups_606271; body: JsonNode): Recallable =
  ## describeBackups
  ## <p> Describes backups. The results are ordered by time, with newest backups first. If you do not specify a BackupId or ServerName, the command returns all backups. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var describeBackups* = Call_DescribeBackups_606271(name: "describeBackups",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeBackups",
    validator: validate_DescribeBackups_606272, base: "/", url: url_DescribeBackups_606273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_606286 = ref object of OpenApiRestCall_605589
proc url_DescribeEvents_606288(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEvents_606287(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeEvents"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_DescribeEvents_606286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Describes events for a specified server. Results are ordered by time, with newest events first. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_DescribeEvents_606286; body: JsonNode): Recallable =
  ## describeEvents
  ## <p> Describes events for a specified server. Results are ordered by time, with newest events first. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var describeEvents* = Call_DescribeEvents_606286(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeEvents",
    validator: validate_DescribeEvents_606287, base: "/", url: url_DescribeEvents_606288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNodeAssociationStatus_606301 = ref object of OpenApiRestCall_605589
proc url_DescribeNodeAssociationStatus_606303(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNodeAssociationStatus_606302(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeNodeAssociationStatus"))
  if valid_606304 != nil:
    section.add "X-Amz-Target", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_DescribeNodeAssociationStatus_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns the current status of an existing association or disassociation request. </p> <p> A <code>ResourceNotFoundException</code> is thrown when no recent association or disassociation request with the specified token is found, or when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_DescribeNodeAssociationStatus_606301; body: JsonNode): Recallable =
  ## describeNodeAssociationStatus
  ## <p> Returns the current status of an existing association or disassociation request. </p> <p> A <code>ResourceNotFoundException</code> is thrown when no recent association or disassociation request with the specified token is found, or when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var describeNodeAssociationStatus* = Call_DescribeNodeAssociationStatus_606301(
    name: "describeNodeAssociationStatus", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com", route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeNodeAssociationStatus",
    validator: validate_DescribeNodeAssociationStatus_606302, base: "/",
    url: url_DescribeNodeAssociationStatus_606303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServers_606316 = ref object of OpenApiRestCall_605589
proc url_DescribeServers_606318(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServers_606317(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeServers"))
  if valid_606319 != nil:
    section.add "X-Amz-Target", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Algorithm")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Algorithm", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-SignedHeaders", valid_606326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_DescribeServers_606316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Lists all configuration management servers that are identified with your account. Only the stored results from Amazon DynamoDB are returned. AWS OpsWorks CM does not query other services. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_DescribeServers_606316; body: JsonNode): Recallable =
  ## describeServers
  ## <p> Lists all configuration management servers that are identified with your account. Only the stored results from Amazon DynamoDB are returned. AWS OpsWorks CM does not query other services. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var describeServers* = Call_DescribeServers_606316(name: "describeServers",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeServers",
    validator: validate_DescribeServers_606317, base: "/", url: url_DescribeServers_606318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateNode_606331 = ref object of OpenApiRestCall_605589
proc url_DisassociateNode_606333(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateNode_606332(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DisassociateNode"))
  if valid_606334 != nil:
    section.add "X-Amz-Target", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_DisassociateNode_606331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Disassociates a node from an AWS OpsWorks CM server, and removes the node from the server's managed nodes. After a node is disassociated, the node key pair is no longer valid for accessing the configuration manager's API. For more information about how to associate a node, see <a>AssociateNode</a>. </p> <p>A node can can only be disassociated from a server that is in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_DisassociateNode_606331; body: JsonNode): Recallable =
  ## disassociateNode
  ## <p> Disassociates a node from an AWS OpsWorks CM server, and removes the node from the server's managed nodes. After a node is disassociated, the node key pair is no longer valid for accessing the configuration manager's API. For more information about how to associate a node, see <a>AssociateNode</a>. </p> <p>A node can can only be disassociated from a server that is in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var disassociateNode* = Call_DisassociateNode_606331(name: "disassociateNode",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DisassociateNode",
    validator: validate_DisassociateNode_606332, base: "/",
    url: url_DisassociateNode_606333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportServerEngineAttribute_606346 = ref object of OpenApiRestCall_605589
proc url_ExportServerEngineAttribute_606348(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExportServerEngineAttribute_606347(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606349 = header.getOrDefault("X-Amz-Target")
  valid_606349 = validateParameter(valid_606349, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.ExportServerEngineAttribute"))
  if valid_606349 != nil:
    section.add "X-Amz-Target", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_ExportServerEngineAttribute_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Exports a specified server engine attribute as a base64-encoded string. For example, you can export user data that you can use in EC2 to associate nodes with a server. </p> <p> This operation is synchronous. </p> <p> A <code>ValidationException</code> is raised when parameters of the request are not valid. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. An <code>InvalidStateException</code> is thrown when the server is in any of the following states: CREATING, TERMINATED, FAILED or DELETING. </p>
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_ExportServerEngineAttribute_606346; body: JsonNode): Recallable =
  ## exportServerEngineAttribute
  ## <p> Exports a specified server engine attribute as a base64-encoded string. For example, you can export user data that you can use in EC2 to associate nodes with a server. </p> <p> This operation is synchronous. </p> <p> A <code>ValidationException</code> is raised when parameters of the request are not valid. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. An <code>InvalidStateException</code> is thrown when the server is in any of the following states: CREATING, TERMINATED, FAILED or DELETING. </p>
  ##   body: JObject (required)
  var body_606360 = newJObject()
  if body != nil:
    body_606360 = body
  result = call_606359.call(nil, nil, nil, nil, body_606360)

var exportServerEngineAttribute* = Call_ExportServerEngineAttribute_606346(
    name: "exportServerEngineAttribute", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.ExportServerEngineAttribute",
    validator: validate_ExportServerEngineAttribute_606347, base: "/",
    url: url_ExportServerEngineAttribute_606348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606361 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606363(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_606362(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of tags that are applied to the specified AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise servers or backups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606364 = header.getOrDefault("X-Amz-Target")
  valid_606364 = validateParameter(valid_606364, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.ListTagsForResource"))
  if valid_606364 != nil:
    section.add "X-Amz-Target", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Signature")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Signature", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Content-Sha256", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Date")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Date", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Credential")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Credential", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_ListTagsForResource_606361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags that are applied to the specified AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise servers or backups.
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_ListTagsForResource_606361; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of tags that are applied to the specified AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise servers or backups.
  ##   body: JObject (required)
  var body_606375 = newJObject()
  if body != nil:
    body_606375 = body
  result = call_606374.call(nil, nil, nil, nil, body_606375)

var listTagsForResource* = Call_ListTagsForResource_606361(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.ListTagsForResource",
    validator: validate_ListTagsForResource_606362, base: "/",
    url: url_ListTagsForResource_606363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreServer_606376 = ref object of OpenApiRestCall_605589
proc url_RestoreServer_606378(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RestoreServer_606377(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Restores a backup to a server that is in a <code>CONNECTION_LOST</code>, <code>HEALTHY</code>, <code>RUNNING</code>, <code>UNHEALTHY</code>, or <code>TERMINATED</code> state. When you run RestoreServer, the server's EC2 instance is deleted, and a new EC2 instance is configured. RestoreServer maintains the existing server endpoint, so configuration management of the server's client devices (nodes) should continue to work. </p> <p>Restoring from a backup is performed by creating a new EC2 instance. If restoration is successful, and the server is in a <code>HEALTHY</code> state, AWS OpsWorks CM switches traffic over to the new instance. After restoration is finished, the old EC2 instance is maintained in a <code>Running</code> or <code>Stopped</code> state, but is eventually terminated.</p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when the server is not in a valid state. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606379 = header.getOrDefault("X-Amz-Target")
  valid_606379 = validateParameter(valid_606379, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.RestoreServer"))
  if valid_606379 != nil:
    section.add "X-Amz-Target", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_RestoreServer_606376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Restores a backup to a server that is in a <code>CONNECTION_LOST</code>, <code>HEALTHY</code>, <code>RUNNING</code>, <code>UNHEALTHY</code>, or <code>TERMINATED</code> state. When you run RestoreServer, the server's EC2 instance is deleted, and a new EC2 instance is configured. RestoreServer maintains the existing server endpoint, so configuration management of the server's client devices (nodes) should continue to work. </p> <p>Restoring from a backup is performed by creating a new EC2 instance. If restoration is successful, and the server is in a <code>HEALTHY</code> state, AWS OpsWorks CM switches traffic over to the new instance. After restoration is finished, the old EC2 instance is maintained in a <code>Running</code> or <code>Stopped</code> state, but is eventually terminated.</p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when the server is not in a valid state. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_RestoreServer_606376; body: JsonNode): Recallable =
  ## restoreServer
  ## <p> Restores a backup to a server that is in a <code>CONNECTION_LOST</code>, <code>HEALTHY</code>, <code>RUNNING</code>, <code>UNHEALTHY</code>, or <code>TERMINATED</code> state. When you run RestoreServer, the server's EC2 instance is deleted, and a new EC2 instance is configured. RestoreServer maintains the existing server endpoint, so configuration management of the server's client devices (nodes) should continue to work. </p> <p>Restoring from a backup is performed by creating a new EC2 instance. If restoration is successful, and the server is in a <code>HEALTHY</code> state, AWS OpsWorks CM switches traffic over to the new instance. After restoration is finished, the old EC2 instance is maintained in a <code>Running</code> or <code>Stopped</code> state, but is eventually terminated.</p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when the server is not in a valid state. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  result = call_606389.call(nil, nil, nil, nil, body_606390)

var restoreServer* = Call_RestoreServer_606376(name: "restoreServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.RestoreServer",
    validator: validate_RestoreServer_606377, base: "/", url: url_RestoreServer_606378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMaintenance_606391 = ref object of OpenApiRestCall_605589
proc url_StartMaintenance_606393(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMaintenance_606392(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606394 = header.getOrDefault("X-Amz-Target")
  valid_606394 = validateParameter(valid_606394, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.StartMaintenance"))
  if valid_606394 != nil:
    section.add "X-Amz-Target", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_StartMaintenance_606391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Manually starts server maintenance. This command can be useful if an earlier maintenance attempt failed, and the underlying cause of maintenance failure has been resolved. The server is in an <code>UNDER_MAINTENANCE</code> state while maintenance is in progress. </p> <p> Maintenance can only be started on servers in <code>HEALTHY</code> and <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_StartMaintenance_606391; body: JsonNode): Recallable =
  ## startMaintenance
  ## <p> Manually starts server maintenance. This command can be useful if an earlier maintenance attempt failed, and the underlying cause of maintenance failure has been resolved. The server is in an <code>UNDER_MAINTENANCE</code> state while maintenance is in progress. </p> <p> Maintenance can only be started on servers in <code>HEALTHY</code> and <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_606405 = newJObject()
  if body != nil:
    body_606405 = body
  result = call_606404.call(nil, nil, nil, nil, body_606405)

var startMaintenance* = Call_StartMaintenance_606391(name: "startMaintenance",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.StartMaintenance",
    validator: validate_StartMaintenance_606392, base: "/",
    url: url_StartMaintenance_606393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606406 = ref object of OpenApiRestCall_605589
proc url_TagResource_606408(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_606407(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Applies tags to an AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise server, or to server backups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606409 = header.getOrDefault("X-Amz-Target")
  valid_606409 = validateParameter(valid_606409, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.TagResource"))
  if valid_606409 != nil:
    section.add "X-Amz-Target", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Signature")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Signature", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Content-Sha256", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Date")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Date", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Credential")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Credential", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Security-Token")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Security-Token", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Algorithm")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Algorithm", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-SignedHeaders", valid_606416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_TagResource_606406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies tags to an AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise server, or to server backups.
  ## 
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_TagResource_606406; body: JsonNode): Recallable =
  ## tagResource
  ## Applies tags to an AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise server, or to server backups.
  ##   body: JObject (required)
  var body_606420 = newJObject()
  if body != nil:
    body_606420 = body
  result = call_606419.call(nil, nil, nil, nil, body_606420)

var tagResource* = Call_TagResource_606406(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "opsworks-cm.amazonaws.com", route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.TagResource",
                                        validator: validate_TagResource_606407,
                                        base: "/", url: url_TagResource_606408,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606421 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606423(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_606422(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes specified tags from an AWS OpsWorks-CM server or backup.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606424 = header.getOrDefault("X-Amz-Target")
  valid_606424 = validateParameter(valid_606424, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.UntagResource"))
  if valid_606424 != nil:
    section.add "X-Amz-Target", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606433: Call_UntagResource_606421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes specified tags from an AWS OpsWorks-CM server or backup.
  ## 
  let valid = call_606433.validator(path, query, header, formData, body)
  let scheme = call_606433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606433.url(scheme.get, call_606433.host, call_606433.base,
                         call_606433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606433, url, valid)

proc call*(call_606434: Call_UntagResource_606421; body: JsonNode): Recallable =
  ## untagResource
  ## Removes specified tags from an AWS OpsWorks-CM server or backup.
  ##   body: JObject (required)
  var body_606435 = newJObject()
  if body != nil:
    body_606435 = body
  result = call_606434.call(nil, nil, nil, nil, body_606435)

var untagResource* = Call_UntagResource_606421(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.UntagResource",
    validator: validate_UntagResource_606422, base: "/", url: url_UntagResource_606423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServer_606436 = ref object of OpenApiRestCall_605589
proc url_UpdateServer_606438(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateServer_606437(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606439 = header.getOrDefault("X-Amz-Target")
  valid_606439 = validateParameter(valid_606439, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.UpdateServer"))
  if valid_606439 != nil:
    section.add "X-Amz-Target", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Signature")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Signature", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Content-Sha256", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Date")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Date", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Credential")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Credential", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Security-Token")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Security-Token", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Algorithm")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Algorithm", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-SignedHeaders", valid_606446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606448: Call_UpdateServer_606436; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Updates settings for a server. </p> <p> This operation is synchronous. </p>
  ## 
  let valid = call_606448.validator(path, query, header, formData, body)
  let scheme = call_606448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606448.url(scheme.get, call_606448.host, call_606448.base,
                         call_606448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606448, url, valid)

proc call*(call_606449: Call_UpdateServer_606436; body: JsonNode): Recallable =
  ## updateServer
  ## <p> Updates settings for a server. </p> <p> This operation is synchronous. </p>
  ##   body: JObject (required)
  var body_606450 = newJObject()
  if body != nil:
    body_606450 = body
  result = call_606449.call(nil, nil, nil, nil, body_606450)

var updateServer* = Call_UpdateServer_606436(name: "updateServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.UpdateServer",
    validator: validate_UpdateServer_606437, base: "/", url: url_UpdateServer_606438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServerEngineAttributes_606451 = ref object of OpenApiRestCall_605589
proc url_UpdateServerEngineAttributes_606453(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateServerEngineAttributes_606452(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606454 = header.getOrDefault("X-Amz-Target")
  valid_606454 = validateParameter(valid_606454, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.UpdateServerEngineAttributes"))
  if valid_606454 != nil:
    section.add "X-Amz-Target", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_UpdateServerEngineAttributes_606451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Updates engine-specific attributes on a specified server. The server enters the <code>MODIFYING</code> state when this operation is in progress. Only one update can occur at a time. You can use this command to reset a Chef server's public key (<code>CHEF_PIVOTAL_KEY</code>) or a Puppet server's admin password (<code>PUPPET_ADMIN_PASSWORD</code>). </p> <p> This operation is asynchronous. </p> <p> This operation can only be called for servers in <code>HEALTHY</code> or <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is raised. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_UpdateServerEngineAttributes_606451; body: JsonNode): Recallable =
  ## updateServerEngineAttributes
  ## <p> Updates engine-specific attributes on a specified server. The server enters the <code>MODIFYING</code> state when this operation is in progress. Only one update can occur at a time. You can use this command to reset a Chef server's public key (<code>CHEF_PIVOTAL_KEY</code>) or a Puppet server's admin password (<code>PUPPET_ADMIN_PASSWORD</code>). </p> <p> This operation is asynchronous. </p> <p> This operation can only be called for servers in <code>HEALTHY</code> or <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is raised. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_606465 = newJObject()
  if body != nil:
    body_606465 = body
  result = call_606464.call(nil, nil, nil, nil, body_606465)

var updateServerEngineAttributes* = Call_UpdateServerEngineAttributes_606451(
    name: "updateServerEngineAttributes", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com", route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.UpdateServerEngineAttributes",
    validator: validate_UpdateServerEngineAttributes_606452, base: "/",
    url: url_UpdateServerEngineAttributes_606453,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
