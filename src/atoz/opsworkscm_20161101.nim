
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

  OpenApiRestCall_604658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_604658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_604658): Option[Scheme] {.used.} =
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
  Call_AssociateNode_604996 = ref object of OpenApiRestCall_604658
proc url_AssociateNode_604998(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateNode_604997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605123 = header.getOrDefault("X-Amz-Target")
  valid_605123 = validateParameter(valid_605123, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.AssociateNode"))
  if valid_605123 != nil:
    section.add "X-Amz-Target", valid_605123
  var valid_605124 = header.getOrDefault("X-Amz-Signature")
  valid_605124 = validateParameter(valid_605124, JString, required = false,
                                 default = nil)
  if valid_605124 != nil:
    section.add "X-Amz-Signature", valid_605124
  var valid_605125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605125 = validateParameter(valid_605125, JString, required = false,
                                 default = nil)
  if valid_605125 != nil:
    section.add "X-Amz-Content-Sha256", valid_605125
  var valid_605126 = header.getOrDefault("X-Amz-Date")
  valid_605126 = validateParameter(valid_605126, JString, required = false,
                                 default = nil)
  if valid_605126 != nil:
    section.add "X-Amz-Date", valid_605126
  var valid_605127 = header.getOrDefault("X-Amz-Credential")
  valid_605127 = validateParameter(valid_605127, JString, required = false,
                                 default = nil)
  if valid_605127 != nil:
    section.add "X-Amz-Credential", valid_605127
  var valid_605128 = header.getOrDefault("X-Amz-Security-Token")
  valid_605128 = validateParameter(valid_605128, JString, required = false,
                                 default = nil)
  if valid_605128 != nil:
    section.add "X-Amz-Security-Token", valid_605128
  var valid_605129 = header.getOrDefault("X-Amz-Algorithm")
  valid_605129 = validateParameter(valid_605129, JString, required = false,
                                 default = nil)
  if valid_605129 != nil:
    section.add "X-Amz-Algorithm", valid_605129
  var valid_605130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605130 = validateParameter(valid_605130, JString, required = false,
                                 default = nil)
  if valid_605130 != nil:
    section.add "X-Amz-SignedHeaders", valid_605130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605154: Call_AssociateNode_604996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Associates a new node with the server. For more information about how to disassociate a node, see <a>DisassociateNode</a>.</p> <p> On a Chef server: This command is an alternative to <code>knife bootstrap</code>.</p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>CHEF_ORGANIZATION</i>,Value=default" "Name=<i>CHEF_NODE_PUBLIC_KEY</i>,Value=<i>public-key-pem</i>"</code> </p> <p> On a Puppet server, this command is an alternative to the <code>puppet cert sign</code> command that signs a Puppet node CSR. </p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>PUPPET_NODE_CSR</i>,Value=<i>csr-pem</i>"</code> </p> <p> A node can can only be associated with servers that are in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. The AssociateNode API call can be integrated into Auto Scaling configurations, AWS Cloudformation templates, or the user data of a server's instance. </p>
  ## 
  let valid = call_605154.validator(path, query, header, formData, body)
  let scheme = call_605154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605154.url(scheme.get, call_605154.host, call_605154.base,
                         call_605154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605154, url, valid)

proc call*(call_605225: Call_AssociateNode_604996; body: JsonNode): Recallable =
  ## associateNode
  ## <p> Associates a new node with the server. For more information about how to disassociate a node, see <a>DisassociateNode</a>.</p> <p> On a Chef server: This command is an alternative to <code>knife bootstrap</code>.</p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>CHEF_ORGANIZATION</i>,Value=default" "Name=<i>CHEF_NODE_PUBLIC_KEY</i>,Value=<i>public-key-pem</i>"</code> </p> <p> On a Puppet server, this command is an alternative to the <code>puppet cert sign</code> command that signs a Puppet node CSR. </p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>PUPPET_NODE_CSR</i>,Value=<i>csr-pem</i>"</code> </p> <p> A node can can only be associated with servers that are in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. The AssociateNode API call can be integrated into Auto Scaling configurations, AWS Cloudformation templates, or the user data of a server's instance. </p>
  ##   body: JObject (required)
  var body_605226 = newJObject()
  if body != nil:
    body_605226 = body
  result = call_605225.call(nil, nil, nil, nil, body_605226)

var associateNode* = Call_AssociateNode_604996(name: "associateNode",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.AssociateNode",
    validator: validate_AssociateNode_604997, base: "/", url: url_AssociateNode_604998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackup_605265 = ref object of OpenApiRestCall_604658
proc url_CreateBackup_605267(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBackup_605266(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605268 = header.getOrDefault("X-Amz-Target")
  valid_605268 = validateParameter(valid_605268, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.CreateBackup"))
  if valid_605268 != nil:
    section.add "X-Amz-Target", valid_605268
  var valid_605269 = header.getOrDefault("X-Amz-Signature")
  valid_605269 = validateParameter(valid_605269, JString, required = false,
                                 default = nil)
  if valid_605269 != nil:
    section.add "X-Amz-Signature", valid_605269
  var valid_605270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605270 = validateParameter(valid_605270, JString, required = false,
                                 default = nil)
  if valid_605270 != nil:
    section.add "X-Amz-Content-Sha256", valid_605270
  var valid_605271 = header.getOrDefault("X-Amz-Date")
  valid_605271 = validateParameter(valid_605271, JString, required = false,
                                 default = nil)
  if valid_605271 != nil:
    section.add "X-Amz-Date", valid_605271
  var valid_605272 = header.getOrDefault("X-Amz-Credential")
  valid_605272 = validateParameter(valid_605272, JString, required = false,
                                 default = nil)
  if valid_605272 != nil:
    section.add "X-Amz-Credential", valid_605272
  var valid_605273 = header.getOrDefault("X-Amz-Security-Token")
  valid_605273 = validateParameter(valid_605273, JString, required = false,
                                 default = nil)
  if valid_605273 != nil:
    section.add "X-Amz-Security-Token", valid_605273
  var valid_605274 = header.getOrDefault("X-Amz-Algorithm")
  valid_605274 = validateParameter(valid_605274, JString, required = false,
                                 default = nil)
  if valid_605274 != nil:
    section.add "X-Amz-Algorithm", valid_605274
  var valid_605275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605275 = validateParameter(valid_605275, JString, required = false,
                                 default = nil)
  if valid_605275 != nil:
    section.add "X-Amz-SignedHeaders", valid_605275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605277: Call_CreateBackup_605265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Creates an application-level backup of a server. While the server is in the <code>BACKING_UP</code> state, the server cannot be changed, and no additional backup can be created. </p> <p> Backups can be created for servers in <code>RUNNING</code>, <code>HEALTHY</code>, and <code>UNHEALTHY</code> states. By default, you can create a maximum of 50 manual backups. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when the maximum number of manual backups is reached. An <code>InvalidStateException</code> is thrown when the server is not in any of the following states: RUNNING, HEALTHY, or UNHEALTHY. A <code>ResourceNotFoundException</code> is thrown when the server is not found. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ## 
  let valid = call_605277.validator(path, query, header, formData, body)
  let scheme = call_605277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605277.url(scheme.get, call_605277.host, call_605277.base,
                         call_605277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605277, url, valid)

proc call*(call_605278: Call_CreateBackup_605265; body: JsonNode): Recallable =
  ## createBackup
  ## <p> Creates an application-level backup of a server. While the server is in the <code>BACKING_UP</code> state, the server cannot be changed, and no additional backup can be created. </p> <p> Backups can be created for servers in <code>RUNNING</code>, <code>HEALTHY</code>, and <code>UNHEALTHY</code> states. By default, you can create a maximum of 50 manual backups. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when the maximum number of manual backups is reached. An <code>InvalidStateException</code> is thrown when the server is not in any of the following states: RUNNING, HEALTHY, or UNHEALTHY. A <code>ResourceNotFoundException</code> is thrown when the server is not found. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_605279 = newJObject()
  if body != nil:
    body_605279 = body
  result = call_605278.call(nil, nil, nil, nil, body_605279)

var createBackup* = Call_CreateBackup_605265(name: "createBackup",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.CreateBackup",
    validator: validate_CreateBackup_605266, base: "/", url: url_CreateBackup_605267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateServer_605280 = ref object of OpenApiRestCall_604658
proc url_CreateServer_605282(protocol: Scheme; host: string; base: string;
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

proc validate_CreateServer_605281(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605283 = header.getOrDefault("X-Amz-Target")
  valid_605283 = validateParameter(valid_605283, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.CreateServer"))
  if valid_605283 != nil:
    section.add "X-Amz-Target", valid_605283
  var valid_605284 = header.getOrDefault("X-Amz-Signature")
  valid_605284 = validateParameter(valid_605284, JString, required = false,
                                 default = nil)
  if valid_605284 != nil:
    section.add "X-Amz-Signature", valid_605284
  var valid_605285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605285 = validateParameter(valid_605285, JString, required = false,
                                 default = nil)
  if valid_605285 != nil:
    section.add "X-Amz-Content-Sha256", valid_605285
  var valid_605286 = header.getOrDefault("X-Amz-Date")
  valid_605286 = validateParameter(valid_605286, JString, required = false,
                                 default = nil)
  if valid_605286 != nil:
    section.add "X-Amz-Date", valid_605286
  var valid_605287 = header.getOrDefault("X-Amz-Credential")
  valid_605287 = validateParameter(valid_605287, JString, required = false,
                                 default = nil)
  if valid_605287 != nil:
    section.add "X-Amz-Credential", valid_605287
  var valid_605288 = header.getOrDefault("X-Amz-Security-Token")
  valid_605288 = validateParameter(valid_605288, JString, required = false,
                                 default = nil)
  if valid_605288 != nil:
    section.add "X-Amz-Security-Token", valid_605288
  var valid_605289 = header.getOrDefault("X-Amz-Algorithm")
  valid_605289 = validateParameter(valid_605289, JString, required = false,
                                 default = nil)
  if valid_605289 != nil:
    section.add "X-Amz-Algorithm", valid_605289
  var valid_605290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605290 = validateParameter(valid_605290, JString, required = false,
                                 default = nil)
  if valid_605290 != nil:
    section.add "X-Amz-SignedHeaders", valid_605290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605292: Call_CreateServer_605280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Creates and immedately starts a new server. The server is ready to use when it is in the <code>HEALTHY</code> state. By default, you can create a maximum of 10 servers. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when you have created the maximum number of servers (10). A <code>ResourceAlreadyExistsException</code> is thrown when a server with the same name already exists in the account. A <code>ResourceNotFoundException</code> is thrown when you specify a backup ID that is not valid or is for a backup that does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p> <p> If you do not specify a security group by adding the <code>SecurityGroupIds</code> parameter, AWS OpsWorks creates a new security group. </p> <p> <i>Chef Automate:</i> The default security group opens the Chef server to the world on TCP port 443. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p> <i>Puppet Enterprise:</i> The default security group opens TCP ports 22, 443, 4433, 8140, 8142, 8143, and 8170. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p>By default, your server is accessible from any IP address. We recommend that you update your security group rules to allow access from known IP addresses and address ranges only. To edit security group rules, open Security Groups in the navigation pane of the EC2 management console. </p> <p>To specify your own domain for a server, and provide your own self-signed or CA-signed certificate and private key, specify values for <code>CustomDomain</code>, <code>CustomCertificate</code>, and <code>CustomPrivateKey</code>.</p>
  ## 
  let valid = call_605292.validator(path, query, header, formData, body)
  let scheme = call_605292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605292.url(scheme.get, call_605292.host, call_605292.base,
                         call_605292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605292, url, valid)

proc call*(call_605293: Call_CreateServer_605280; body: JsonNode): Recallable =
  ## createServer
  ## <p> Creates and immedately starts a new server. The server is ready to use when it is in the <code>HEALTHY</code> state. By default, you can create a maximum of 10 servers. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when you have created the maximum number of servers (10). A <code>ResourceAlreadyExistsException</code> is thrown when a server with the same name already exists in the account. A <code>ResourceNotFoundException</code> is thrown when you specify a backup ID that is not valid or is for a backup that does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p> <p> If you do not specify a security group by adding the <code>SecurityGroupIds</code> parameter, AWS OpsWorks creates a new security group. </p> <p> <i>Chef Automate:</i> The default security group opens the Chef server to the world on TCP port 443. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p> <i>Puppet Enterprise:</i> The default security group opens TCP ports 22, 443, 4433, 8140, 8142, 8143, and 8170. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p>By default, your server is accessible from any IP address. We recommend that you update your security group rules to allow access from known IP addresses and address ranges only. To edit security group rules, open Security Groups in the navigation pane of the EC2 management console. </p> <p>To specify your own domain for a server, and provide your own self-signed or CA-signed certificate and private key, specify values for <code>CustomDomain</code>, <code>CustomCertificate</code>, and <code>CustomPrivateKey</code>.</p>
  ##   body: JObject (required)
  var body_605294 = newJObject()
  if body != nil:
    body_605294 = body
  result = call_605293.call(nil, nil, nil, nil, body_605294)

var createServer* = Call_CreateServer_605280(name: "createServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.CreateServer",
    validator: validate_CreateServer_605281, base: "/", url: url_CreateServer_605282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackup_605295 = ref object of OpenApiRestCall_604658
proc url_DeleteBackup_605297(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBackup_605296(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605298 = header.getOrDefault("X-Amz-Target")
  valid_605298 = validateParameter(valid_605298, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DeleteBackup"))
  if valid_605298 != nil:
    section.add "X-Amz-Target", valid_605298
  var valid_605299 = header.getOrDefault("X-Amz-Signature")
  valid_605299 = validateParameter(valid_605299, JString, required = false,
                                 default = nil)
  if valid_605299 != nil:
    section.add "X-Amz-Signature", valid_605299
  var valid_605300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605300 = validateParameter(valid_605300, JString, required = false,
                                 default = nil)
  if valid_605300 != nil:
    section.add "X-Amz-Content-Sha256", valid_605300
  var valid_605301 = header.getOrDefault("X-Amz-Date")
  valid_605301 = validateParameter(valid_605301, JString, required = false,
                                 default = nil)
  if valid_605301 != nil:
    section.add "X-Amz-Date", valid_605301
  var valid_605302 = header.getOrDefault("X-Amz-Credential")
  valid_605302 = validateParameter(valid_605302, JString, required = false,
                                 default = nil)
  if valid_605302 != nil:
    section.add "X-Amz-Credential", valid_605302
  var valid_605303 = header.getOrDefault("X-Amz-Security-Token")
  valid_605303 = validateParameter(valid_605303, JString, required = false,
                                 default = nil)
  if valid_605303 != nil:
    section.add "X-Amz-Security-Token", valid_605303
  var valid_605304 = header.getOrDefault("X-Amz-Algorithm")
  valid_605304 = validateParameter(valid_605304, JString, required = false,
                                 default = nil)
  if valid_605304 != nil:
    section.add "X-Amz-Algorithm", valid_605304
  var valid_605305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605305 = validateParameter(valid_605305, JString, required = false,
                                 default = nil)
  if valid_605305 != nil:
    section.add "X-Amz-SignedHeaders", valid_605305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605307: Call_DeleteBackup_605295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes a backup. You can delete both manual and automated backups. This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a backup deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ## 
  let valid = call_605307.validator(path, query, header, formData, body)
  let scheme = call_605307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605307.url(scheme.get, call_605307.host, call_605307.base,
                         call_605307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605307, url, valid)

proc call*(call_605308: Call_DeleteBackup_605295; body: JsonNode): Recallable =
  ## deleteBackup
  ## <p> Deletes a backup. You can delete both manual and automated backups. This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a backup deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_605309 = newJObject()
  if body != nil:
    body_605309 = body
  result = call_605308.call(nil, nil, nil, nil, body_605309)

var deleteBackup* = Call_DeleteBackup_605295(name: "deleteBackup",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DeleteBackup",
    validator: validate_DeleteBackup_605296, base: "/", url: url_DeleteBackup_605297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServer_605310 = ref object of OpenApiRestCall_604658
proc url_DeleteServer_605312(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteServer_605311(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605313 = header.getOrDefault("X-Amz-Target")
  valid_605313 = validateParameter(valid_605313, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DeleteServer"))
  if valid_605313 != nil:
    section.add "X-Amz-Target", valid_605313
  var valid_605314 = header.getOrDefault("X-Amz-Signature")
  valid_605314 = validateParameter(valid_605314, JString, required = false,
                                 default = nil)
  if valid_605314 != nil:
    section.add "X-Amz-Signature", valid_605314
  var valid_605315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605315 = validateParameter(valid_605315, JString, required = false,
                                 default = nil)
  if valid_605315 != nil:
    section.add "X-Amz-Content-Sha256", valid_605315
  var valid_605316 = header.getOrDefault("X-Amz-Date")
  valid_605316 = validateParameter(valid_605316, JString, required = false,
                                 default = nil)
  if valid_605316 != nil:
    section.add "X-Amz-Date", valid_605316
  var valid_605317 = header.getOrDefault("X-Amz-Credential")
  valid_605317 = validateParameter(valid_605317, JString, required = false,
                                 default = nil)
  if valid_605317 != nil:
    section.add "X-Amz-Credential", valid_605317
  var valid_605318 = header.getOrDefault("X-Amz-Security-Token")
  valid_605318 = validateParameter(valid_605318, JString, required = false,
                                 default = nil)
  if valid_605318 != nil:
    section.add "X-Amz-Security-Token", valid_605318
  var valid_605319 = header.getOrDefault("X-Amz-Algorithm")
  valid_605319 = validateParameter(valid_605319, JString, required = false,
                                 default = nil)
  if valid_605319 != nil:
    section.add "X-Amz-Algorithm", valid_605319
  var valid_605320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605320 = validateParameter(valid_605320, JString, required = false,
                                 default = nil)
  if valid_605320 != nil:
    section.add "X-Amz-SignedHeaders", valid_605320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605322: Call_DeleteServer_605310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes the server and the underlying AWS CloudFormation stacks (including the server's EC2 instance). When you run this command, the server state is updated to <code>DELETING</code>. After the server is deleted, it is no longer returned by <code>DescribeServer</code> requests. If the AWS CloudFormation stack cannot be deleted, the server cannot be deleted. </p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a server deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p> <p> </p>
  ## 
  let valid = call_605322.validator(path, query, header, formData, body)
  let scheme = call_605322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605322.url(scheme.get, call_605322.host, call_605322.base,
                         call_605322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605322, url, valid)

proc call*(call_605323: Call_DeleteServer_605310; body: JsonNode): Recallable =
  ## deleteServer
  ## <p> Deletes the server and the underlying AWS CloudFormation stacks (including the server's EC2 instance). When you run this command, the server state is updated to <code>DELETING</code>. After the server is deleted, it is no longer returned by <code>DescribeServer</code> requests. If the AWS CloudFormation stack cannot be deleted, the server cannot be deleted. </p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a server deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p> <p> </p>
  ##   body: JObject (required)
  var body_605324 = newJObject()
  if body != nil:
    body_605324 = body
  result = call_605323.call(nil, nil, nil, nil, body_605324)

var deleteServer* = Call_DeleteServer_605310(name: "deleteServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DeleteServer",
    validator: validate_DeleteServer_605311, base: "/", url: url_DeleteServer_605312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountAttributes_605325 = ref object of OpenApiRestCall_604658
proc url_DescribeAccountAttributes_605327(protocol: Scheme; host: string;
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

proc validate_DescribeAccountAttributes_605326(path: JsonNode; query: JsonNode;
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
  var valid_605328 = header.getOrDefault("X-Amz-Target")
  valid_605328 = validateParameter(valid_605328, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeAccountAttributes"))
  if valid_605328 != nil:
    section.add "X-Amz-Target", valid_605328
  var valid_605329 = header.getOrDefault("X-Amz-Signature")
  valid_605329 = validateParameter(valid_605329, JString, required = false,
                                 default = nil)
  if valid_605329 != nil:
    section.add "X-Amz-Signature", valid_605329
  var valid_605330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605330 = validateParameter(valid_605330, JString, required = false,
                                 default = nil)
  if valid_605330 != nil:
    section.add "X-Amz-Content-Sha256", valid_605330
  var valid_605331 = header.getOrDefault("X-Amz-Date")
  valid_605331 = validateParameter(valid_605331, JString, required = false,
                                 default = nil)
  if valid_605331 != nil:
    section.add "X-Amz-Date", valid_605331
  var valid_605332 = header.getOrDefault("X-Amz-Credential")
  valid_605332 = validateParameter(valid_605332, JString, required = false,
                                 default = nil)
  if valid_605332 != nil:
    section.add "X-Amz-Credential", valid_605332
  var valid_605333 = header.getOrDefault("X-Amz-Security-Token")
  valid_605333 = validateParameter(valid_605333, JString, required = false,
                                 default = nil)
  if valid_605333 != nil:
    section.add "X-Amz-Security-Token", valid_605333
  var valid_605334 = header.getOrDefault("X-Amz-Algorithm")
  valid_605334 = validateParameter(valid_605334, JString, required = false,
                                 default = nil)
  if valid_605334 != nil:
    section.add "X-Amz-Algorithm", valid_605334
  var valid_605335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605335 = validateParameter(valid_605335, JString, required = false,
                                 default = nil)
  if valid_605335 != nil:
    section.add "X-Amz-SignedHeaders", valid_605335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605337: Call_DescribeAccountAttributes_605325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Describes your OpsWorks-CM account attributes. </p> <p> This operation is synchronous. </p>
  ## 
  let valid = call_605337.validator(path, query, header, formData, body)
  let scheme = call_605337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605337.url(scheme.get, call_605337.host, call_605337.base,
                         call_605337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605337, url, valid)

proc call*(call_605338: Call_DescribeAccountAttributes_605325; body: JsonNode): Recallable =
  ## describeAccountAttributes
  ## <p> Describes your OpsWorks-CM account attributes. </p> <p> This operation is synchronous. </p>
  ##   body: JObject (required)
  var body_605339 = newJObject()
  if body != nil:
    body_605339 = body
  result = call_605338.call(nil, nil, nil, nil, body_605339)

var describeAccountAttributes* = Call_DescribeAccountAttributes_605325(
    name: "describeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeAccountAttributes",
    validator: validate_DescribeAccountAttributes_605326, base: "/",
    url: url_DescribeAccountAttributes_605327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackups_605340 = ref object of OpenApiRestCall_604658
proc url_DescribeBackups_605342(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeBackups_605341(path: JsonNode; query: JsonNode;
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
  var valid_605343 = header.getOrDefault("X-Amz-Target")
  valid_605343 = validateParameter(valid_605343, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeBackups"))
  if valid_605343 != nil:
    section.add "X-Amz-Target", valid_605343
  var valid_605344 = header.getOrDefault("X-Amz-Signature")
  valid_605344 = validateParameter(valid_605344, JString, required = false,
                                 default = nil)
  if valid_605344 != nil:
    section.add "X-Amz-Signature", valid_605344
  var valid_605345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605345 = validateParameter(valid_605345, JString, required = false,
                                 default = nil)
  if valid_605345 != nil:
    section.add "X-Amz-Content-Sha256", valid_605345
  var valid_605346 = header.getOrDefault("X-Amz-Date")
  valid_605346 = validateParameter(valid_605346, JString, required = false,
                                 default = nil)
  if valid_605346 != nil:
    section.add "X-Amz-Date", valid_605346
  var valid_605347 = header.getOrDefault("X-Amz-Credential")
  valid_605347 = validateParameter(valid_605347, JString, required = false,
                                 default = nil)
  if valid_605347 != nil:
    section.add "X-Amz-Credential", valid_605347
  var valid_605348 = header.getOrDefault("X-Amz-Security-Token")
  valid_605348 = validateParameter(valid_605348, JString, required = false,
                                 default = nil)
  if valid_605348 != nil:
    section.add "X-Amz-Security-Token", valid_605348
  var valid_605349 = header.getOrDefault("X-Amz-Algorithm")
  valid_605349 = validateParameter(valid_605349, JString, required = false,
                                 default = nil)
  if valid_605349 != nil:
    section.add "X-Amz-Algorithm", valid_605349
  var valid_605350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605350 = validateParameter(valid_605350, JString, required = false,
                                 default = nil)
  if valid_605350 != nil:
    section.add "X-Amz-SignedHeaders", valid_605350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605352: Call_DescribeBackups_605340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Describes backups. The results are ordered by time, with newest backups first. If you do not specify a BackupId or ServerName, the command returns all backups. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_605352.validator(path, query, header, formData, body)
  let scheme = call_605352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605352.url(scheme.get, call_605352.host, call_605352.base,
                         call_605352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605352, url, valid)

proc call*(call_605353: Call_DescribeBackups_605340; body: JsonNode): Recallable =
  ## describeBackups
  ## <p> Describes backups. The results are ordered by time, with newest backups first. If you do not specify a BackupId or ServerName, the command returns all backups. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_605354 = newJObject()
  if body != nil:
    body_605354 = body
  result = call_605353.call(nil, nil, nil, nil, body_605354)

var describeBackups* = Call_DescribeBackups_605340(name: "describeBackups",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeBackups",
    validator: validate_DescribeBackups_605341, base: "/", url: url_DescribeBackups_605342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_605355 = ref object of OpenApiRestCall_604658
proc url_DescribeEvents_605357(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEvents_605356(path: JsonNode; query: JsonNode;
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
  var valid_605358 = header.getOrDefault("X-Amz-Target")
  valid_605358 = validateParameter(valid_605358, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeEvents"))
  if valid_605358 != nil:
    section.add "X-Amz-Target", valid_605358
  var valid_605359 = header.getOrDefault("X-Amz-Signature")
  valid_605359 = validateParameter(valid_605359, JString, required = false,
                                 default = nil)
  if valid_605359 != nil:
    section.add "X-Amz-Signature", valid_605359
  var valid_605360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605360 = validateParameter(valid_605360, JString, required = false,
                                 default = nil)
  if valid_605360 != nil:
    section.add "X-Amz-Content-Sha256", valid_605360
  var valid_605361 = header.getOrDefault("X-Amz-Date")
  valid_605361 = validateParameter(valid_605361, JString, required = false,
                                 default = nil)
  if valid_605361 != nil:
    section.add "X-Amz-Date", valid_605361
  var valid_605362 = header.getOrDefault("X-Amz-Credential")
  valid_605362 = validateParameter(valid_605362, JString, required = false,
                                 default = nil)
  if valid_605362 != nil:
    section.add "X-Amz-Credential", valid_605362
  var valid_605363 = header.getOrDefault("X-Amz-Security-Token")
  valid_605363 = validateParameter(valid_605363, JString, required = false,
                                 default = nil)
  if valid_605363 != nil:
    section.add "X-Amz-Security-Token", valid_605363
  var valid_605364 = header.getOrDefault("X-Amz-Algorithm")
  valid_605364 = validateParameter(valid_605364, JString, required = false,
                                 default = nil)
  if valid_605364 != nil:
    section.add "X-Amz-Algorithm", valid_605364
  var valid_605365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605365 = validateParameter(valid_605365, JString, required = false,
                                 default = nil)
  if valid_605365 != nil:
    section.add "X-Amz-SignedHeaders", valid_605365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605367: Call_DescribeEvents_605355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Describes events for a specified server. Results are ordered by time, with newest events first. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_605367.validator(path, query, header, formData, body)
  let scheme = call_605367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605367.url(scheme.get, call_605367.host, call_605367.base,
                         call_605367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605367, url, valid)

proc call*(call_605368: Call_DescribeEvents_605355; body: JsonNode): Recallable =
  ## describeEvents
  ## <p> Describes events for a specified server. Results are ordered by time, with newest events first. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_605369 = newJObject()
  if body != nil:
    body_605369 = body
  result = call_605368.call(nil, nil, nil, nil, body_605369)

var describeEvents* = Call_DescribeEvents_605355(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeEvents",
    validator: validate_DescribeEvents_605356, base: "/", url: url_DescribeEvents_605357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNodeAssociationStatus_605370 = ref object of OpenApiRestCall_604658
proc url_DescribeNodeAssociationStatus_605372(protocol: Scheme; host: string;
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

proc validate_DescribeNodeAssociationStatus_605371(path: JsonNode; query: JsonNode;
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
  var valid_605373 = header.getOrDefault("X-Amz-Target")
  valid_605373 = validateParameter(valid_605373, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeNodeAssociationStatus"))
  if valid_605373 != nil:
    section.add "X-Amz-Target", valid_605373
  var valid_605374 = header.getOrDefault("X-Amz-Signature")
  valid_605374 = validateParameter(valid_605374, JString, required = false,
                                 default = nil)
  if valid_605374 != nil:
    section.add "X-Amz-Signature", valid_605374
  var valid_605375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605375 = validateParameter(valid_605375, JString, required = false,
                                 default = nil)
  if valid_605375 != nil:
    section.add "X-Amz-Content-Sha256", valid_605375
  var valid_605376 = header.getOrDefault("X-Amz-Date")
  valid_605376 = validateParameter(valid_605376, JString, required = false,
                                 default = nil)
  if valid_605376 != nil:
    section.add "X-Amz-Date", valid_605376
  var valid_605377 = header.getOrDefault("X-Amz-Credential")
  valid_605377 = validateParameter(valid_605377, JString, required = false,
                                 default = nil)
  if valid_605377 != nil:
    section.add "X-Amz-Credential", valid_605377
  var valid_605378 = header.getOrDefault("X-Amz-Security-Token")
  valid_605378 = validateParameter(valid_605378, JString, required = false,
                                 default = nil)
  if valid_605378 != nil:
    section.add "X-Amz-Security-Token", valid_605378
  var valid_605379 = header.getOrDefault("X-Amz-Algorithm")
  valid_605379 = validateParameter(valid_605379, JString, required = false,
                                 default = nil)
  if valid_605379 != nil:
    section.add "X-Amz-Algorithm", valid_605379
  var valid_605380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605380 = validateParameter(valid_605380, JString, required = false,
                                 default = nil)
  if valid_605380 != nil:
    section.add "X-Amz-SignedHeaders", valid_605380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605382: Call_DescribeNodeAssociationStatus_605370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns the current status of an existing association or disassociation request. </p> <p> A <code>ResourceNotFoundException</code> is thrown when no recent association or disassociation request with the specified token is found, or when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_605382.validator(path, query, header, formData, body)
  let scheme = call_605382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605382.url(scheme.get, call_605382.host, call_605382.base,
                         call_605382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605382, url, valid)

proc call*(call_605383: Call_DescribeNodeAssociationStatus_605370; body: JsonNode): Recallable =
  ## describeNodeAssociationStatus
  ## <p> Returns the current status of an existing association or disassociation request. </p> <p> A <code>ResourceNotFoundException</code> is thrown when no recent association or disassociation request with the specified token is found, or when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_605384 = newJObject()
  if body != nil:
    body_605384 = body
  result = call_605383.call(nil, nil, nil, nil, body_605384)

var describeNodeAssociationStatus* = Call_DescribeNodeAssociationStatus_605370(
    name: "describeNodeAssociationStatus", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com", route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeNodeAssociationStatus",
    validator: validate_DescribeNodeAssociationStatus_605371, base: "/",
    url: url_DescribeNodeAssociationStatus_605372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServers_605385 = ref object of OpenApiRestCall_604658
proc url_DescribeServers_605387(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeServers_605386(path: JsonNode; query: JsonNode;
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
  var valid_605388 = header.getOrDefault("X-Amz-Target")
  valid_605388 = validateParameter(valid_605388, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeServers"))
  if valid_605388 != nil:
    section.add "X-Amz-Target", valid_605388
  var valid_605389 = header.getOrDefault("X-Amz-Signature")
  valid_605389 = validateParameter(valid_605389, JString, required = false,
                                 default = nil)
  if valid_605389 != nil:
    section.add "X-Amz-Signature", valid_605389
  var valid_605390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605390 = validateParameter(valid_605390, JString, required = false,
                                 default = nil)
  if valid_605390 != nil:
    section.add "X-Amz-Content-Sha256", valid_605390
  var valid_605391 = header.getOrDefault("X-Amz-Date")
  valid_605391 = validateParameter(valid_605391, JString, required = false,
                                 default = nil)
  if valid_605391 != nil:
    section.add "X-Amz-Date", valid_605391
  var valid_605392 = header.getOrDefault("X-Amz-Credential")
  valid_605392 = validateParameter(valid_605392, JString, required = false,
                                 default = nil)
  if valid_605392 != nil:
    section.add "X-Amz-Credential", valid_605392
  var valid_605393 = header.getOrDefault("X-Amz-Security-Token")
  valid_605393 = validateParameter(valid_605393, JString, required = false,
                                 default = nil)
  if valid_605393 != nil:
    section.add "X-Amz-Security-Token", valid_605393
  var valid_605394 = header.getOrDefault("X-Amz-Algorithm")
  valid_605394 = validateParameter(valid_605394, JString, required = false,
                                 default = nil)
  if valid_605394 != nil:
    section.add "X-Amz-Algorithm", valid_605394
  var valid_605395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605395 = validateParameter(valid_605395, JString, required = false,
                                 default = nil)
  if valid_605395 != nil:
    section.add "X-Amz-SignedHeaders", valid_605395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605397: Call_DescribeServers_605385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Lists all configuration management servers that are identified with your account. Only the stored results from Amazon DynamoDB are returned. AWS OpsWorks CM does not query other services. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_605397.validator(path, query, header, formData, body)
  let scheme = call_605397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605397.url(scheme.get, call_605397.host, call_605397.base,
                         call_605397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605397, url, valid)

proc call*(call_605398: Call_DescribeServers_605385; body: JsonNode): Recallable =
  ## describeServers
  ## <p> Lists all configuration management servers that are identified with your account. Only the stored results from Amazon DynamoDB are returned. AWS OpsWorks CM does not query other services. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_605399 = newJObject()
  if body != nil:
    body_605399 = body
  result = call_605398.call(nil, nil, nil, nil, body_605399)

var describeServers* = Call_DescribeServers_605385(name: "describeServers",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeServers",
    validator: validate_DescribeServers_605386, base: "/", url: url_DescribeServers_605387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateNode_605400 = ref object of OpenApiRestCall_604658
proc url_DisassociateNode_605402(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateNode_605401(path: JsonNode; query: JsonNode;
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
  var valid_605403 = header.getOrDefault("X-Amz-Target")
  valid_605403 = validateParameter(valid_605403, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DisassociateNode"))
  if valid_605403 != nil:
    section.add "X-Amz-Target", valid_605403
  var valid_605404 = header.getOrDefault("X-Amz-Signature")
  valid_605404 = validateParameter(valid_605404, JString, required = false,
                                 default = nil)
  if valid_605404 != nil:
    section.add "X-Amz-Signature", valid_605404
  var valid_605405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605405 = validateParameter(valid_605405, JString, required = false,
                                 default = nil)
  if valid_605405 != nil:
    section.add "X-Amz-Content-Sha256", valid_605405
  var valid_605406 = header.getOrDefault("X-Amz-Date")
  valid_605406 = validateParameter(valid_605406, JString, required = false,
                                 default = nil)
  if valid_605406 != nil:
    section.add "X-Amz-Date", valid_605406
  var valid_605407 = header.getOrDefault("X-Amz-Credential")
  valid_605407 = validateParameter(valid_605407, JString, required = false,
                                 default = nil)
  if valid_605407 != nil:
    section.add "X-Amz-Credential", valid_605407
  var valid_605408 = header.getOrDefault("X-Amz-Security-Token")
  valid_605408 = validateParameter(valid_605408, JString, required = false,
                                 default = nil)
  if valid_605408 != nil:
    section.add "X-Amz-Security-Token", valid_605408
  var valid_605409 = header.getOrDefault("X-Amz-Algorithm")
  valid_605409 = validateParameter(valid_605409, JString, required = false,
                                 default = nil)
  if valid_605409 != nil:
    section.add "X-Amz-Algorithm", valid_605409
  var valid_605410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605410 = validateParameter(valid_605410, JString, required = false,
                                 default = nil)
  if valid_605410 != nil:
    section.add "X-Amz-SignedHeaders", valid_605410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605412: Call_DisassociateNode_605400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Disassociates a node from an AWS OpsWorks CM server, and removes the node from the server's managed nodes. After a node is disassociated, the node key pair is no longer valid for accessing the configuration manager's API. For more information about how to associate a node, see <a>AssociateNode</a>. </p> <p>A node can can only be disassociated from a server that is in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_605412.validator(path, query, header, formData, body)
  let scheme = call_605412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605412.url(scheme.get, call_605412.host, call_605412.base,
                         call_605412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605412, url, valid)

proc call*(call_605413: Call_DisassociateNode_605400; body: JsonNode): Recallable =
  ## disassociateNode
  ## <p> Disassociates a node from an AWS OpsWorks CM server, and removes the node from the server's managed nodes. After a node is disassociated, the node key pair is no longer valid for accessing the configuration manager's API. For more information about how to associate a node, see <a>AssociateNode</a>. </p> <p>A node can can only be disassociated from a server that is in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_605414 = newJObject()
  if body != nil:
    body_605414 = body
  result = call_605413.call(nil, nil, nil, nil, body_605414)

var disassociateNode* = Call_DisassociateNode_605400(name: "disassociateNode",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DisassociateNode",
    validator: validate_DisassociateNode_605401, base: "/",
    url: url_DisassociateNode_605402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportServerEngineAttribute_605415 = ref object of OpenApiRestCall_604658
proc url_ExportServerEngineAttribute_605417(protocol: Scheme; host: string;
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

proc validate_ExportServerEngineAttribute_605416(path: JsonNode; query: JsonNode;
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
  var valid_605418 = header.getOrDefault("X-Amz-Target")
  valid_605418 = validateParameter(valid_605418, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.ExportServerEngineAttribute"))
  if valid_605418 != nil:
    section.add "X-Amz-Target", valid_605418
  var valid_605419 = header.getOrDefault("X-Amz-Signature")
  valid_605419 = validateParameter(valid_605419, JString, required = false,
                                 default = nil)
  if valid_605419 != nil:
    section.add "X-Amz-Signature", valid_605419
  var valid_605420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605420 = validateParameter(valid_605420, JString, required = false,
                                 default = nil)
  if valid_605420 != nil:
    section.add "X-Amz-Content-Sha256", valid_605420
  var valid_605421 = header.getOrDefault("X-Amz-Date")
  valid_605421 = validateParameter(valid_605421, JString, required = false,
                                 default = nil)
  if valid_605421 != nil:
    section.add "X-Amz-Date", valid_605421
  var valid_605422 = header.getOrDefault("X-Amz-Credential")
  valid_605422 = validateParameter(valid_605422, JString, required = false,
                                 default = nil)
  if valid_605422 != nil:
    section.add "X-Amz-Credential", valid_605422
  var valid_605423 = header.getOrDefault("X-Amz-Security-Token")
  valid_605423 = validateParameter(valid_605423, JString, required = false,
                                 default = nil)
  if valid_605423 != nil:
    section.add "X-Amz-Security-Token", valid_605423
  var valid_605424 = header.getOrDefault("X-Amz-Algorithm")
  valid_605424 = validateParameter(valid_605424, JString, required = false,
                                 default = nil)
  if valid_605424 != nil:
    section.add "X-Amz-Algorithm", valid_605424
  var valid_605425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605425 = validateParameter(valid_605425, JString, required = false,
                                 default = nil)
  if valid_605425 != nil:
    section.add "X-Amz-SignedHeaders", valid_605425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605427: Call_ExportServerEngineAttribute_605415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Exports a specified server engine attribute as a base64-encoded string. For example, you can export user data that you can use in EC2 to associate nodes with a server. </p> <p> This operation is synchronous. </p> <p> A <code>ValidationException</code> is raised when parameters of the request are not valid. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. An <code>InvalidStateException</code> is thrown when the server is in any of the following states: CREATING, TERMINATED, FAILED or DELETING. </p>
  ## 
  let valid = call_605427.validator(path, query, header, formData, body)
  let scheme = call_605427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605427.url(scheme.get, call_605427.host, call_605427.base,
                         call_605427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605427, url, valid)

proc call*(call_605428: Call_ExportServerEngineAttribute_605415; body: JsonNode): Recallable =
  ## exportServerEngineAttribute
  ## <p> Exports a specified server engine attribute as a base64-encoded string. For example, you can export user data that you can use in EC2 to associate nodes with a server. </p> <p> This operation is synchronous. </p> <p> A <code>ValidationException</code> is raised when parameters of the request are not valid. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. An <code>InvalidStateException</code> is thrown when the server is in any of the following states: CREATING, TERMINATED, FAILED or DELETING. </p>
  ##   body: JObject (required)
  var body_605429 = newJObject()
  if body != nil:
    body_605429 = body
  result = call_605428.call(nil, nil, nil, nil, body_605429)

var exportServerEngineAttribute* = Call_ExportServerEngineAttribute_605415(
    name: "exportServerEngineAttribute", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.ExportServerEngineAttribute",
    validator: validate_ExportServerEngineAttribute_605416, base: "/",
    url: url_ExportServerEngineAttribute_605417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_605430 = ref object of OpenApiRestCall_604658
proc url_ListTagsForResource_605432(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_605431(path: JsonNode; query: JsonNode;
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
  var valid_605433 = header.getOrDefault("X-Amz-Target")
  valid_605433 = validateParameter(valid_605433, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.ListTagsForResource"))
  if valid_605433 != nil:
    section.add "X-Amz-Target", valid_605433
  var valid_605434 = header.getOrDefault("X-Amz-Signature")
  valid_605434 = validateParameter(valid_605434, JString, required = false,
                                 default = nil)
  if valid_605434 != nil:
    section.add "X-Amz-Signature", valid_605434
  var valid_605435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605435 = validateParameter(valid_605435, JString, required = false,
                                 default = nil)
  if valid_605435 != nil:
    section.add "X-Amz-Content-Sha256", valid_605435
  var valid_605436 = header.getOrDefault("X-Amz-Date")
  valid_605436 = validateParameter(valid_605436, JString, required = false,
                                 default = nil)
  if valid_605436 != nil:
    section.add "X-Amz-Date", valid_605436
  var valid_605437 = header.getOrDefault("X-Amz-Credential")
  valid_605437 = validateParameter(valid_605437, JString, required = false,
                                 default = nil)
  if valid_605437 != nil:
    section.add "X-Amz-Credential", valid_605437
  var valid_605438 = header.getOrDefault("X-Amz-Security-Token")
  valid_605438 = validateParameter(valid_605438, JString, required = false,
                                 default = nil)
  if valid_605438 != nil:
    section.add "X-Amz-Security-Token", valid_605438
  var valid_605439 = header.getOrDefault("X-Amz-Algorithm")
  valid_605439 = validateParameter(valid_605439, JString, required = false,
                                 default = nil)
  if valid_605439 != nil:
    section.add "X-Amz-Algorithm", valid_605439
  var valid_605440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605440 = validateParameter(valid_605440, JString, required = false,
                                 default = nil)
  if valid_605440 != nil:
    section.add "X-Amz-SignedHeaders", valid_605440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605442: Call_ListTagsForResource_605430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags that are applied to the specified AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise servers or backups.
  ## 
  let valid = call_605442.validator(path, query, header, formData, body)
  let scheme = call_605442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605442.url(scheme.get, call_605442.host, call_605442.base,
                         call_605442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605442, url, valid)

proc call*(call_605443: Call_ListTagsForResource_605430; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of tags that are applied to the specified AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise servers or backups.
  ##   body: JObject (required)
  var body_605444 = newJObject()
  if body != nil:
    body_605444 = body
  result = call_605443.call(nil, nil, nil, nil, body_605444)

var listTagsForResource* = Call_ListTagsForResource_605430(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.ListTagsForResource",
    validator: validate_ListTagsForResource_605431, base: "/",
    url: url_ListTagsForResource_605432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreServer_605445 = ref object of OpenApiRestCall_604658
proc url_RestoreServer_605447(protocol: Scheme; host: string; base: string;
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

proc validate_RestoreServer_605446(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605448 = header.getOrDefault("X-Amz-Target")
  valid_605448 = validateParameter(valid_605448, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.RestoreServer"))
  if valid_605448 != nil:
    section.add "X-Amz-Target", valid_605448
  var valid_605449 = header.getOrDefault("X-Amz-Signature")
  valid_605449 = validateParameter(valid_605449, JString, required = false,
                                 default = nil)
  if valid_605449 != nil:
    section.add "X-Amz-Signature", valid_605449
  var valid_605450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605450 = validateParameter(valid_605450, JString, required = false,
                                 default = nil)
  if valid_605450 != nil:
    section.add "X-Amz-Content-Sha256", valid_605450
  var valid_605451 = header.getOrDefault("X-Amz-Date")
  valid_605451 = validateParameter(valid_605451, JString, required = false,
                                 default = nil)
  if valid_605451 != nil:
    section.add "X-Amz-Date", valid_605451
  var valid_605452 = header.getOrDefault("X-Amz-Credential")
  valid_605452 = validateParameter(valid_605452, JString, required = false,
                                 default = nil)
  if valid_605452 != nil:
    section.add "X-Amz-Credential", valid_605452
  var valid_605453 = header.getOrDefault("X-Amz-Security-Token")
  valid_605453 = validateParameter(valid_605453, JString, required = false,
                                 default = nil)
  if valid_605453 != nil:
    section.add "X-Amz-Security-Token", valid_605453
  var valid_605454 = header.getOrDefault("X-Amz-Algorithm")
  valid_605454 = validateParameter(valid_605454, JString, required = false,
                                 default = nil)
  if valid_605454 != nil:
    section.add "X-Amz-Algorithm", valid_605454
  var valid_605455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605455 = validateParameter(valid_605455, JString, required = false,
                                 default = nil)
  if valid_605455 != nil:
    section.add "X-Amz-SignedHeaders", valid_605455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605457: Call_RestoreServer_605445; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Restores a backup to a server that is in a <code>CONNECTION_LOST</code>, <code>HEALTHY</code>, <code>RUNNING</code>, <code>UNHEALTHY</code>, or <code>TERMINATED</code> state. When you run RestoreServer, the server's EC2 instance is deleted, and a new EC2 instance is configured. RestoreServer maintains the existing server endpoint, so configuration management of the server's client devices (nodes) should continue to work. </p> <p>Restoring from a backup is performed by creating a new EC2 instance. If restoration is successful, and the server is in a <code>HEALTHY</code> state, AWS OpsWorks CM switches traffic over to the new instance. After restoration is finished, the old EC2 instance is maintained in a <code>Running</code> or <code>Stopped</code> state, but is eventually terminated.</p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when the server is not in a valid state. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_605457.validator(path, query, header, formData, body)
  let scheme = call_605457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605457.url(scheme.get, call_605457.host, call_605457.base,
                         call_605457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605457, url, valid)

proc call*(call_605458: Call_RestoreServer_605445; body: JsonNode): Recallable =
  ## restoreServer
  ## <p> Restores a backup to a server that is in a <code>CONNECTION_LOST</code>, <code>HEALTHY</code>, <code>RUNNING</code>, <code>UNHEALTHY</code>, or <code>TERMINATED</code> state. When you run RestoreServer, the server's EC2 instance is deleted, and a new EC2 instance is configured. RestoreServer maintains the existing server endpoint, so configuration management of the server's client devices (nodes) should continue to work. </p> <p>Restoring from a backup is performed by creating a new EC2 instance. If restoration is successful, and the server is in a <code>HEALTHY</code> state, AWS OpsWorks CM switches traffic over to the new instance. After restoration is finished, the old EC2 instance is maintained in a <code>Running</code> or <code>Stopped</code> state, but is eventually terminated.</p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when the server is not in a valid state. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_605459 = newJObject()
  if body != nil:
    body_605459 = body
  result = call_605458.call(nil, nil, nil, nil, body_605459)

var restoreServer* = Call_RestoreServer_605445(name: "restoreServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.RestoreServer",
    validator: validate_RestoreServer_605446, base: "/", url: url_RestoreServer_605447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMaintenance_605460 = ref object of OpenApiRestCall_604658
proc url_StartMaintenance_605462(protocol: Scheme; host: string; base: string;
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

proc validate_StartMaintenance_605461(path: JsonNode; query: JsonNode;
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
  var valid_605463 = header.getOrDefault("X-Amz-Target")
  valid_605463 = validateParameter(valid_605463, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.StartMaintenance"))
  if valid_605463 != nil:
    section.add "X-Amz-Target", valid_605463
  var valid_605464 = header.getOrDefault("X-Amz-Signature")
  valid_605464 = validateParameter(valid_605464, JString, required = false,
                                 default = nil)
  if valid_605464 != nil:
    section.add "X-Amz-Signature", valid_605464
  var valid_605465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605465 = validateParameter(valid_605465, JString, required = false,
                                 default = nil)
  if valid_605465 != nil:
    section.add "X-Amz-Content-Sha256", valid_605465
  var valid_605466 = header.getOrDefault("X-Amz-Date")
  valid_605466 = validateParameter(valid_605466, JString, required = false,
                                 default = nil)
  if valid_605466 != nil:
    section.add "X-Amz-Date", valid_605466
  var valid_605467 = header.getOrDefault("X-Amz-Credential")
  valid_605467 = validateParameter(valid_605467, JString, required = false,
                                 default = nil)
  if valid_605467 != nil:
    section.add "X-Amz-Credential", valid_605467
  var valid_605468 = header.getOrDefault("X-Amz-Security-Token")
  valid_605468 = validateParameter(valid_605468, JString, required = false,
                                 default = nil)
  if valid_605468 != nil:
    section.add "X-Amz-Security-Token", valid_605468
  var valid_605469 = header.getOrDefault("X-Amz-Algorithm")
  valid_605469 = validateParameter(valid_605469, JString, required = false,
                                 default = nil)
  if valid_605469 != nil:
    section.add "X-Amz-Algorithm", valid_605469
  var valid_605470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605470 = validateParameter(valid_605470, JString, required = false,
                                 default = nil)
  if valid_605470 != nil:
    section.add "X-Amz-SignedHeaders", valid_605470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605472: Call_StartMaintenance_605460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Manually starts server maintenance. This command can be useful if an earlier maintenance attempt failed, and the underlying cause of maintenance failure has been resolved. The server is in an <code>UNDER_MAINTENANCE</code> state while maintenance is in progress. </p> <p> Maintenance can only be started on servers in <code>HEALTHY</code> and <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_605472.validator(path, query, header, formData, body)
  let scheme = call_605472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605472.url(scheme.get, call_605472.host, call_605472.base,
                         call_605472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605472, url, valid)

proc call*(call_605473: Call_StartMaintenance_605460; body: JsonNode): Recallable =
  ## startMaintenance
  ## <p> Manually starts server maintenance. This command can be useful if an earlier maintenance attempt failed, and the underlying cause of maintenance failure has been resolved. The server is in an <code>UNDER_MAINTENANCE</code> state while maintenance is in progress. </p> <p> Maintenance can only be started on servers in <code>HEALTHY</code> and <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_605474 = newJObject()
  if body != nil:
    body_605474 = body
  result = call_605473.call(nil, nil, nil, nil, body_605474)

var startMaintenance* = Call_StartMaintenance_605460(name: "startMaintenance",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.StartMaintenance",
    validator: validate_StartMaintenance_605461, base: "/",
    url: url_StartMaintenance_605462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_605475 = ref object of OpenApiRestCall_604658
proc url_TagResource_605477(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_605476(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605478 = header.getOrDefault("X-Amz-Target")
  valid_605478 = validateParameter(valid_605478, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.TagResource"))
  if valid_605478 != nil:
    section.add "X-Amz-Target", valid_605478
  var valid_605479 = header.getOrDefault("X-Amz-Signature")
  valid_605479 = validateParameter(valid_605479, JString, required = false,
                                 default = nil)
  if valid_605479 != nil:
    section.add "X-Amz-Signature", valid_605479
  var valid_605480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605480 = validateParameter(valid_605480, JString, required = false,
                                 default = nil)
  if valid_605480 != nil:
    section.add "X-Amz-Content-Sha256", valid_605480
  var valid_605481 = header.getOrDefault("X-Amz-Date")
  valid_605481 = validateParameter(valid_605481, JString, required = false,
                                 default = nil)
  if valid_605481 != nil:
    section.add "X-Amz-Date", valid_605481
  var valid_605482 = header.getOrDefault("X-Amz-Credential")
  valid_605482 = validateParameter(valid_605482, JString, required = false,
                                 default = nil)
  if valid_605482 != nil:
    section.add "X-Amz-Credential", valid_605482
  var valid_605483 = header.getOrDefault("X-Amz-Security-Token")
  valid_605483 = validateParameter(valid_605483, JString, required = false,
                                 default = nil)
  if valid_605483 != nil:
    section.add "X-Amz-Security-Token", valid_605483
  var valid_605484 = header.getOrDefault("X-Amz-Algorithm")
  valid_605484 = validateParameter(valid_605484, JString, required = false,
                                 default = nil)
  if valid_605484 != nil:
    section.add "X-Amz-Algorithm", valid_605484
  var valid_605485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605485 = validateParameter(valid_605485, JString, required = false,
                                 default = nil)
  if valid_605485 != nil:
    section.add "X-Amz-SignedHeaders", valid_605485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605487: Call_TagResource_605475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies tags to an AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise server, or to server backups.
  ## 
  let valid = call_605487.validator(path, query, header, formData, body)
  let scheme = call_605487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605487.url(scheme.get, call_605487.host, call_605487.base,
                         call_605487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605487, url, valid)

proc call*(call_605488: Call_TagResource_605475; body: JsonNode): Recallable =
  ## tagResource
  ## Applies tags to an AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise server, or to server backups.
  ##   body: JObject (required)
  var body_605489 = newJObject()
  if body != nil:
    body_605489 = body
  result = call_605488.call(nil, nil, nil, nil, body_605489)

var tagResource* = Call_TagResource_605475(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "opsworks-cm.amazonaws.com", route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.TagResource",
                                        validator: validate_TagResource_605476,
                                        base: "/", url: url_TagResource_605477,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_605490 = ref object of OpenApiRestCall_604658
proc url_UntagResource_605492(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_605491(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605493 = header.getOrDefault("X-Amz-Target")
  valid_605493 = validateParameter(valid_605493, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.UntagResource"))
  if valid_605493 != nil:
    section.add "X-Amz-Target", valid_605493
  var valid_605494 = header.getOrDefault("X-Amz-Signature")
  valid_605494 = validateParameter(valid_605494, JString, required = false,
                                 default = nil)
  if valid_605494 != nil:
    section.add "X-Amz-Signature", valid_605494
  var valid_605495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605495 = validateParameter(valid_605495, JString, required = false,
                                 default = nil)
  if valid_605495 != nil:
    section.add "X-Amz-Content-Sha256", valid_605495
  var valid_605496 = header.getOrDefault("X-Amz-Date")
  valid_605496 = validateParameter(valid_605496, JString, required = false,
                                 default = nil)
  if valid_605496 != nil:
    section.add "X-Amz-Date", valid_605496
  var valid_605497 = header.getOrDefault("X-Amz-Credential")
  valid_605497 = validateParameter(valid_605497, JString, required = false,
                                 default = nil)
  if valid_605497 != nil:
    section.add "X-Amz-Credential", valid_605497
  var valid_605498 = header.getOrDefault("X-Amz-Security-Token")
  valid_605498 = validateParameter(valid_605498, JString, required = false,
                                 default = nil)
  if valid_605498 != nil:
    section.add "X-Amz-Security-Token", valid_605498
  var valid_605499 = header.getOrDefault("X-Amz-Algorithm")
  valid_605499 = validateParameter(valid_605499, JString, required = false,
                                 default = nil)
  if valid_605499 != nil:
    section.add "X-Amz-Algorithm", valid_605499
  var valid_605500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605500 = validateParameter(valid_605500, JString, required = false,
                                 default = nil)
  if valid_605500 != nil:
    section.add "X-Amz-SignedHeaders", valid_605500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605502: Call_UntagResource_605490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes specified tags from an AWS OpsWorks-CM server or backup.
  ## 
  let valid = call_605502.validator(path, query, header, formData, body)
  let scheme = call_605502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605502.url(scheme.get, call_605502.host, call_605502.base,
                         call_605502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605502, url, valid)

proc call*(call_605503: Call_UntagResource_605490; body: JsonNode): Recallable =
  ## untagResource
  ## Removes specified tags from an AWS OpsWorks-CM server or backup.
  ##   body: JObject (required)
  var body_605504 = newJObject()
  if body != nil:
    body_605504 = body
  result = call_605503.call(nil, nil, nil, nil, body_605504)

var untagResource* = Call_UntagResource_605490(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.UntagResource",
    validator: validate_UntagResource_605491, base: "/", url: url_UntagResource_605492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServer_605505 = ref object of OpenApiRestCall_604658
proc url_UpdateServer_605507(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateServer_605506(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605508 = header.getOrDefault("X-Amz-Target")
  valid_605508 = validateParameter(valid_605508, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.UpdateServer"))
  if valid_605508 != nil:
    section.add "X-Amz-Target", valid_605508
  var valid_605509 = header.getOrDefault("X-Amz-Signature")
  valid_605509 = validateParameter(valid_605509, JString, required = false,
                                 default = nil)
  if valid_605509 != nil:
    section.add "X-Amz-Signature", valid_605509
  var valid_605510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605510 = validateParameter(valid_605510, JString, required = false,
                                 default = nil)
  if valid_605510 != nil:
    section.add "X-Amz-Content-Sha256", valid_605510
  var valid_605511 = header.getOrDefault("X-Amz-Date")
  valid_605511 = validateParameter(valid_605511, JString, required = false,
                                 default = nil)
  if valid_605511 != nil:
    section.add "X-Amz-Date", valid_605511
  var valid_605512 = header.getOrDefault("X-Amz-Credential")
  valid_605512 = validateParameter(valid_605512, JString, required = false,
                                 default = nil)
  if valid_605512 != nil:
    section.add "X-Amz-Credential", valid_605512
  var valid_605513 = header.getOrDefault("X-Amz-Security-Token")
  valid_605513 = validateParameter(valid_605513, JString, required = false,
                                 default = nil)
  if valid_605513 != nil:
    section.add "X-Amz-Security-Token", valid_605513
  var valid_605514 = header.getOrDefault("X-Amz-Algorithm")
  valid_605514 = validateParameter(valid_605514, JString, required = false,
                                 default = nil)
  if valid_605514 != nil:
    section.add "X-Amz-Algorithm", valid_605514
  var valid_605515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605515 = validateParameter(valid_605515, JString, required = false,
                                 default = nil)
  if valid_605515 != nil:
    section.add "X-Amz-SignedHeaders", valid_605515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605517: Call_UpdateServer_605505; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Updates settings for a server. </p> <p> This operation is synchronous. </p>
  ## 
  let valid = call_605517.validator(path, query, header, formData, body)
  let scheme = call_605517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605517.url(scheme.get, call_605517.host, call_605517.base,
                         call_605517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605517, url, valid)

proc call*(call_605518: Call_UpdateServer_605505; body: JsonNode): Recallable =
  ## updateServer
  ## <p> Updates settings for a server. </p> <p> This operation is synchronous. </p>
  ##   body: JObject (required)
  var body_605519 = newJObject()
  if body != nil:
    body_605519 = body
  result = call_605518.call(nil, nil, nil, nil, body_605519)

var updateServer* = Call_UpdateServer_605505(name: "updateServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.UpdateServer",
    validator: validate_UpdateServer_605506, base: "/", url: url_UpdateServer_605507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServerEngineAttributes_605520 = ref object of OpenApiRestCall_604658
proc url_UpdateServerEngineAttributes_605522(protocol: Scheme; host: string;
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

proc validate_UpdateServerEngineAttributes_605521(path: JsonNode; query: JsonNode;
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
  var valid_605523 = header.getOrDefault("X-Amz-Target")
  valid_605523 = validateParameter(valid_605523, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.UpdateServerEngineAttributes"))
  if valid_605523 != nil:
    section.add "X-Amz-Target", valid_605523
  var valid_605524 = header.getOrDefault("X-Amz-Signature")
  valid_605524 = validateParameter(valid_605524, JString, required = false,
                                 default = nil)
  if valid_605524 != nil:
    section.add "X-Amz-Signature", valid_605524
  var valid_605525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605525 = validateParameter(valid_605525, JString, required = false,
                                 default = nil)
  if valid_605525 != nil:
    section.add "X-Amz-Content-Sha256", valid_605525
  var valid_605526 = header.getOrDefault("X-Amz-Date")
  valid_605526 = validateParameter(valid_605526, JString, required = false,
                                 default = nil)
  if valid_605526 != nil:
    section.add "X-Amz-Date", valid_605526
  var valid_605527 = header.getOrDefault("X-Amz-Credential")
  valid_605527 = validateParameter(valid_605527, JString, required = false,
                                 default = nil)
  if valid_605527 != nil:
    section.add "X-Amz-Credential", valid_605527
  var valid_605528 = header.getOrDefault("X-Amz-Security-Token")
  valid_605528 = validateParameter(valid_605528, JString, required = false,
                                 default = nil)
  if valid_605528 != nil:
    section.add "X-Amz-Security-Token", valid_605528
  var valid_605529 = header.getOrDefault("X-Amz-Algorithm")
  valid_605529 = validateParameter(valid_605529, JString, required = false,
                                 default = nil)
  if valid_605529 != nil:
    section.add "X-Amz-Algorithm", valid_605529
  var valid_605530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605530 = validateParameter(valid_605530, JString, required = false,
                                 default = nil)
  if valid_605530 != nil:
    section.add "X-Amz-SignedHeaders", valid_605530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605532: Call_UpdateServerEngineAttributes_605520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Updates engine-specific attributes on a specified server. The server enters the <code>MODIFYING</code> state when this operation is in progress. Only one update can occur at a time. You can use this command to reset a Chef server's public key (<code>CHEF_PIVOTAL_KEY</code>) or a Puppet server's admin password (<code>PUPPET_ADMIN_PASSWORD</code>). </p> <p> This operation is asynchronous. </p> <p> This operation can only be called for servers in <code>HEALTHY</code> or <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is raised. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ## 
  let valid = call_605532.validator(path, query, header, formData, body)
  let scheme = call_605532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605532.url(scheme.get, call_605532.host, call_605532.base,
                         call_605532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605532, url, valid)

proc call*(call_605533: Call_UpdateServerEngineAttributes_605520; body: JsonNode): Recallable =
  ## updateServerEngineAttributes
  ## <p> Updates engine-specific attributes on a specified server. The server enters the <code>MODIFYING</code> state when this operation is in progress. Only one update can occur at a time. You can use this command to reset a Chef server's public key (<code>CHEF_PIVOTAL_KEY</code>) or a Puppet server's admin password (<code>PUPPET_ADMIN_PASSWORD</code>). </p> <p> This operation is asynchronous. </p> <p> This operation can only be called for servers in <code>HEALTHY</code> or <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is raised. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   body: JObject (required)
  var body_605534 = newJObject()
  if body != nil:
    body_605534 = body
  result = call_605533.call(nil, nil, nil, nil, body_605534)

var updateServerEngineAttributes* = Call_UpdateServerEngineAttributes_605520(
    name: "updateServerEngineAttributes", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com", route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.UpdateServerEngineAttributes",
    validator: validate_UpdateServerEngineAttributes_605521, base: "/",
    url: url_UpdateServerEngineAttributes_605522,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
