
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "opsworks-cm.ap-northeast-1.amazonaws.com", "ap-southeast-1": "opsworks-cm.ap-southeast-1.amazonaws.com", "us-west-2": "opsworks-cm.us-west-2.amazonaws.com", "eu-west-2": "opsworks-cm.eu-west-2.amazonaws.com", "ap-northeast-3": "opsworks-cm.ap-northeast-3.amazonaws.com", "eu-central-1": "opsworks-cm.eu-central-1.amazonaws.com", "us-east-2": "opsworks-cm.us-east-2.amazonaws.com", "us-east-1": "opsworks-cm.us-east-1.amazonaws.com", "cn-northwest-1": "opsworks-cm.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "opsworks-cm.ap-south-1.amazonaws.com", "eu-north-1": "opsworks-cm.eu-north-1.amazonaws.com", "ap-northeast-2": "opsworks-cm.ap-northeast-2.amazonaws.com", "us-west-1": "opsworks-cm.us-west-1.amazonaws.com", "us-gov-east-1": "opsworks-cm.us-gov-east-1.amazonaws.com", "eu-west-3": "opsworks-cm.eu-west-3.amazonaws.com", "cn-north-1": "opsworks-cm.cn-north-1.amazonaws.com.cn", "sa-east-1": "opsworks-cm.sa-east-1.amazonaws.com", "eu-west-1": "opsworks-cm.eu-west-1.amazonaws.com", "us-gov-west-1": "opsworks-cm.us-gov-west-1.amazonaws.com", "ap-southeast-2": "opsworks-cm.ap-southeast-2.amazonaws.com", "ca-central-1": "opsworks-cm.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AssociateNode_402656294 = ref object of OpenApiRestCall_402656044
proc url_AssociateNode_402656296(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateNode_402656295(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.AssociateNode"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656412: Call_AssociateNode_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Associates a new node with the server. For more information about how to disassociate a node, see <a>DisassociateNode</a>.</p> <p> On a Chef server: This command is an alternative to <code>knife bootstrap</code>.</p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>CHEF_ORGANIZATION</i>,Value=default" "Name=<i>CHEF_NODE_PUBLIC_KEY</i>,Value=<i>public-key-pem</i>"</code> </p> <p> On a Puppet server, this command is an alternative to the <code>puppet cert sign</code> command that signs a Puppet node CSR. </p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>PUPPET_NODE_CSR</i>,Value=<i>csr-pem</i>"</code> </p> <p> A node can can only be associated with servers that are in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. The AssociateNode API call can be integrated into Auto Scaling configurations, AWS Cloudformation templates, or the user data of a server's instance. </p>
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_AssociateNode_402656294; body: JsonNode): Recallable =
  ## associateNode
  ## <p> Associates a new node with the server. For more information about how to disassociate a node, see <a>DisassociateNode</a>.</p> <p> On a Chef server: This command is an alternative to <code>knife bootstrap</code>.</p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>CHEF_ORGANIZATION</i>,Value=default" "Name=<i>CHEF_NODE_PUBLIC_KEY</i>,Value=<i>public-key-pem</i>"</code> </p> <p> On a Puppet server, this command is an alternative to the <code>puppet cert sign</code> command that signs a Puppet node CSR. </p> <p> Example (Chef): <code>aws opsworks-cm associate-node --server-name <i>MyServer</i> --node-name <i>MyManagedNode</i> --engine-attributes "Name=<i>PUPPET_NODE_CSR</i>,Value=<i>csr-pem</i>"</code> </p> <p> A node can can only be associated with servers that are in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. The AssociateNode API call can be integrated into Auto Scaling configurations, AWS Cloudformation templates, or the user data of a server's instance. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var associateNode* = Call_AssociateNode_402656294(name: "associateNode",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.AssociateNode",
    validator: validate_AssociateNode_402656295, base: "/",
    makeUrl: url_AssociateNode_402656296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackup_402656489 = ref object of OpenApiRestCall_402656044
proc url_CreateBackup_402656491(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBackup_402656490(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.CreateBackup"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656501: Call_CreateBackup_402656489; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Creates an application-level backup of a server. While the server is in the <code>BACKING_UP</code> state, the server cannot be changed, and no additional backup can be created. </p> <p> Backups can be created for servers in <code>RUNNING</code>, <code>HEALTHY</code>, and <code>UNHEALTHY</code> states. By default, you can create a maximum of 50 manual backups. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when the maximum number of manual backups is reached. An <code>InvalidStateException</code> is thrown when the server is not in any of the following states: RUNNING, HEALTHY, or UNHEALTHY. A <code>ResourceNotFoundException</code> is thrown when the server is not found. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_CreateBackup_402656489; body: JsonNode): Recallable =
  ## createBackup
  ## <p> Creates an application-level backup of a server. While the server is in the <code>BACKING_UP</code> state, the server cannot be changed, and no additional backup can be created. </p> <p> Backups can be created for servers in <code>RUNNING</code>, <code>HEALTHY</code>, and <code>UNHEALTHY</code> states. By default, you can create a maximum of 50 manual backups. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when the maximum number of manual backups is reached. An <code>InvalidStateException</code> is thrown when the server is not in any of the following states: RUNNING, HEALTHY, or UNHEALTHY. A <code>ResourceNotFoundException</code> is thrown when the server is not found. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var createBackup* = Call_CreateBackup_402656489(name: "createBackup",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.CreateBackup",
    validator: validate_CreateBackup_402656490, base: "/",
    makeUrl: url_CreateBackup_402656491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateServer_402656504 = ref object of OpenApiRestCall_402656044
proc url_CreateServer_402656506(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateServer_402656505(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.CreateServer"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656516: Call_CreateServer_402656504; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Creates and immedately starts a new server. The server is ready to use when it is in the <code>HEALTHY</code> state. By default, you can create a maximum of 10 servers. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when you have created the maximum number of servers (10). A <code>ResourceAlreadyExistsException</code> is thrown when a server with the same name already exists in the account. A <code>ResourceNotFoundException</code> is thrown when you specify a backup ID that is not valid or is for a backup that does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p> <p> If you do not specify a security group by adding the <code>SecurityGroupIds</code> parameter, AWS OpsWorks creates a new security group. </p> <p> <i>Chef Automate:</i> The default security group opens the Chef server to the world on TCP port 443. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p> <i>Puppet Enterprise:</i> The default security group opens TCP ports 22, 443, 4433, 8140, 8142, 8143, and 8170. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p>By default, your server is accessible from any IP address. We recommend that you update your security group rules to allow access from known IP addresses and address ranges only. To edit security group rules, open Security Groups in the navigation pane of the EC2 management console. </p> <p>To specify your own domain for a server, and provide your own self-signed or CA-signed certificate and private key, specify values for <code>CustomDomain</code>, <code>CustomCertificate</code>, and <code>CustomPrivateKey</code>.</p>
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_CreateServer_402656504; body: JsonNode): Recallable =
  ## createServer
  ## <p> Creates and immedately starts a new server. The server is ready to use when it is in the <code>HEALTHY</code> state. By default, you can create a maximum of 10 servers. </p> <p> This operation is asynchronous. </p> <p> A <code>LimitExceededException</code> is thrown when you have created the maximum number of servers (10). A <code>ResourceAlreadyExistsException</code> is thrown when a server with the same name already exists in the account. A <code>ResourceNotFoundException</code> is thrown when you specify a backup ID that is not valid or is for a backup that does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p> <p> If you do not specify a security group by adding the <code>SecurityGroupIds</code> parameter, AWS OpsWorks creates a new security group. </p> <p> <i>Chef Automate:</i> The default security group opens the Chef server to the world on TCP port 443. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p> <i>Puppet Enterprise:</i> The default security group opens TCP ports 22, 443, 4433, 8140, 8142, 8143, and 8170. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. </p> <p>By default, your server is accessible from any IP address. We recommend that you update your security group rules to allow access from known IP addresses and address ranges only. To edit security group rules, open Security Groups in the navigation pane of the EC2 management console. </p> <p>To specify your own domain for a server, and provide your own self-signed or CA-signed certificate and private key, specify values for <code>CustomDomain</code>, <code>CustomCertificate</code>, and <code>CustomPrivateKey</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var createServer* = Call_CreateServer_402656504(name: "createServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.CreateServer",
    validator: validate_CreateServer_402656505, base: "/",
    makeUrl: url_CreateServer_402656506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackup_402656519 = ref object of OpenApiRestCall_402656044
proc url_DeleteBackup_402656521(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBackup_402656520(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DeleteBackup"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656531: Call_DeleteBackup_402656519; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Deletes a backup. You can delete both manual and automated backups. This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a backup deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_DeleteBackup_402656519; body: JsonNode): Recallable =
  ## deleteBackup
  ## <p> Deletes a backup. You can delete both manual and automated backups. This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a backup deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is thrown when parameters of the request are not valid. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var deleteBackup* = Call_DeleteBackup_402656519(name: "deleteBackup",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DeleteBackup",
    validator: validate_DeleteBackup_402656520, base: "/",
    makeUrl: url_DeleteBackup_402656521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServer_402656534 = ref object of OpenApiRestCall_402656044
proc url_DeleteServer_402656536(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteServer_402656535(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DeleteServer"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656546: Call_DeleteServer_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Deletes the server and the underlying AWS CloudFormation stacks (including the server's EC2 instance). When you run this command, the server state is updated to <code>DELETING</code>. After the server is deleted, it is no longer returned by <code>DescribeServer</code> requests. If the AWS CloudFormation stack cannot be deleted, the server cannot be deleted. </p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a server deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p> <p> </p>
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_DeleteServer_402656534; body: JsonNode): Recallable =
  ## deleteServer
  ## <p> Deletes the server and the underlying AWS CloudFormation stacks (including the server's EC2 instance). When you run this command, the server state is updated to <code>DELETING</code>. After the server is deleted, it is no longer returned by <code>DescribeServer</code> requests. If the AWS CloudFormation stack cannot be deleted, the server cannot be deleted. </p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when a server deletion is already in progress. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p> <p> </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var deleteServer* = Call_DeleteServer_402656534(name: "deleteServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DeleteServer",
    validator: validate_DeleteServer_402656535, base: "/",
    makeUrl: url_DeleteServer_402656536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountAttributes_402656549 = ref object of OpenApiRestCall_402656044
proc url_DescribeAccountAttributes_402656551(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAccountAttributes_402656550(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeAccountAttributes"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656561: Call_DescribeAccountAttributes_402656549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Describes your OpsWorks-CM account attributes. </p> <p> This operation is synchronous. </p>
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_DescribeAccountAttributes_402656549;
           body: JsonNode): Recallable =
  ## describeAccountAttributes
  ## <p> Describes your OpsWorks-CM account attributes. </p> <p> This operation is synchronous. </p>
  ##   
                                                                                                    ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var describeAccountAttributes* = Call_DescribeAccountAttributes_402656549(
    name: "describeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeAccountAttributes",
    validator: validate_DescribeAccountAttributes_402656550, base: "/",
    makeUrl: url_DescribeAccountAttributes_402656551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackups_402656564 = ref object of OpenApiRestCall_402656044
proc url_DescribeBackups_402656566(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBackups_402656565(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeBackups"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656576: Call_DescribeBackups_402656564; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Describes backups. The results are ordered by time, with newest backups first. If you do not specify a BackupId or ServerName, the command returns all backups. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_DescribeBackups_402656564; body: JsonNode): Recallable =
  ## describeBackups
  ## <p> Describes backups. The results are ordered by time, with newest backups first. If you do not specify a BackupId or ServerName, the command returns all backups. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the backup does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var describeBackups* = Call_DescribeBackups_402656564(name: "describeBackups",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeBackups",
    validator: validate_DescribeBackups_402656565, base: "/",
    makeUrl: url_DescribeBackups_402656566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_402656579 = ref object of OpenApiRestCall_402656044
proc url_DescribeEvents_402656581(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEvents_402656580(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeEvents"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656591: Call_DescribeEvents_402656579; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Describes events for a specified server. Results are ordered by time, with newest events first. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_DescribeEvents_402656579; body: JsonNode): Recallable =
  ## describeEvents
  ## <p> Describes events for a specified server. Results are ordered by time, with newest events first. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var describeEvents* = Call_DescribeEvents_402656579(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeEvents",
    validator: validate_DescribeEvents_402656580, base: "/",
    makeUrl: url_DescribeEvents_402656581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNodeAssociationStatus_402656594 = ref object of OpenApiRestCall_402656044
proc url_DescribeNodeAssociationStatus_402656596(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNodeAssociationStatus_402656595(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeNodeAssociationStatus"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656606: Call_DescribeNodeAssociationStatus_402656594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Returns the current status of an existing association or disassociation request. </p> <p> A <code>ResourceNotFoundException</code> is thrown when no recent association or disassociation request with the specified token is found, or when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_DescribeNodeAssociationStatus_402656594;
           body: JsonNode): Recallable =
  ## describeNodeAssociationStatus
  ## <p> Returns the current status of an existing association or disassociation request. </p> <p> A <code>ResourceNotFoundException</code> is thrown when no recent association or disassociation request with the specified token is found, or when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var describeNodeAssociationStatus* = Call_DescribeNodeAssociationStatus_402656594(
    name: "describeNodeAssociationStatus", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com", route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeNodeAssociationStatus",
    validator: validate_DescribeNodeAssociationStatus_402656595, base: "/",
    makeUrl: url_DescribeNodeAssociationStatus_402656596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServers_402656609 = ref object of OpenApiRestCall_402656044
proc url_DescribeServers_402656611(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServers_402656610(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DescribeServers"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656621: Call_DescribeServers_402656609; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Lists all configuration management servers that are identified with your account. Only the stored results from Amazon DynamoDB are returned. AWS OpsWorks CM does not query other services. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_DescribeServers_402656609; body: JsonNode): Recallable =
  ## describeServers
  ## <p> Lists all configuration management servers that are identified with your account. Only the stored results from Amazon DynamoDB are returned. AWS OpsWorks CM does not query other services. </p> <p> This operation is synchronous. </p> <p> A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var describeServers* = Call_DescribeServers_402656609(name: "describeServers",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DescribeServers",
    validator: validate_DescribeServers_402656610, base: "/",
    makeUrl: url_DescribeServers_402656611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateNode_402656624 = ref object of OpenApiRestCall_402656044
proc url_DisassociateNode_402656626(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateNode_402656625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.DisassociateNode"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656636: Call_DisassociateNode_402656624;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Disassociates a node from an AWS OpsWorks CM server, and removes the node from the server's managed nodes. After a node is disassociated, the node key pair is no longer valid for accessing the configuration manager's API. For more information about how to associate a node, see <a>AssociateNode</a>. </p> <p>A node can can only be disassociated from a server that is in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_DisassociateNode_402656624; body: JsonNode): Recallable =
  ## disassociateNode
  ## <p> Disassociates a node from an AWS OpsWorks CM server, and removes the node from the server's managed nodes. After a node is disassociated, the node key pair is no longer valid for accessing the configuration manager's API. For more information about how to associate a node, see <a>AssociateNode</a>. </p> <p>A node can can only be disassociated from a server that is in a <code>HEALTHY</code> state. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var disassociateNode* = Call_DisassociateNode_402656624(
    name: "disassociateNode", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.DisassociateNode",
    validator: validate_DisassociateNode_402656625, base: "/",
    makeUrl: url_DisassociateNode_402656626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportServerEngineAttribute_402656639 = ref object of OpenApiRestCall_402656044
proc url_ExportServerEngineAttribute_402656641(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExportServerEngineAttribute_402656640(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.ExportServerEngineAttribute"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656651: Call_ExportServerEngineAttribute_402656639;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Exports a specified server engine attribute as a base64-encoded string. For example, you can export user data that you can use in EC2 to associate nodes with a server. </p> <p> This operation is synchronous. </p> <p> A <code>ValidationException</code> is raised when parameters of the request are not valid. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. An <code>InvalidStateException</code> is thrown when the server is in any of the following states: CREATING, TERMINATED, FAILED or DELETING. </p>
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_ExportServerEngineAttribute_402656639;
           body: JsonNode): Recallable =
  ## exportServerEngineAttribute
  ## <p> Exports a specified server engine attribute as a base64-encoded string. For example, you can export user data that you can use in EC2 to associate nodes with a server. </p> <p> This operation is synchronous. </p> <p> A <code>ValidationException</code> is raised when parameters of the request are not valid. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. An <code>InvalidStateException</code> is thrown when the server is in any of the following states: CREATING, TERMINATED, FAILED or DELETING. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var exportServerEngineAttribute* = Call_ExportServerEngineAttribute_402656639(
    name: "exportServerEngineAttribute", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.ExportServerEngineAttribute",
    validator: validate_ExportServerEngineAttribute_402656640, base: "/",
    makeUrl: url_ExportServerEngineAttribute_402656641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656654 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656656(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_402656655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.ListTagsForResource"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656666: Call_ListTagsForResource_402656654;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of tags that are applied to the specified AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise servers or backups.
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_ListTagsForResource_402656654; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of tags that are applied to the specified AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise servers or backups.
  ##   
                                                                                                                                                      ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var listTagsForResource* = Call_ListTagsForResource_402656654(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.ListTagsForResource",
    validator: validate_ListTagsForResource_402656655, base: "/",
    makeUrl: url_ListTagsForResource_402656656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreServer_402656669 = ref object of OpenApiRestCall_402656044
proc url_RestoreServer_402656671(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RestoreServer_402656670(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.RestoreServer"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656681: Call_RestoreServer_402656669; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Restores a backup to a server that is in a <code>CONNECTION_LOST</code>, <code>HEALTHY</code>, <code>RUNNING</code>, <code>UNHEALTHY</code>, or <code>TERMINATED</code> state. When you run RestoreServer, the server's EC2 instance is deleted, and a new EC2 instance is configured. RestoreServer maintains the existing server endpoint, so configuration management of the server's client devices (nodes) should continue to work. </p> <p>Restoring from a backup is performed by creating a new EC2 instance. If restoration is successful, and the server is in a <code>HEALTHY</code> state, AWS OpsWorks CM switches traffic over to the new instance. After restoration is finished, the old EC2 instance is maintained in a <code>Running</code> or <code>Stopped</code> state, but is eventually terminated.</p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when the server is not in a valid state. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_RestoreServer_402656669; body: JsonNode): Recallable =
  ## restoreServer
  ## <p> Restores a backup to a server that is in a <code>CONNECTION_LOST</code>, <code>HEALTHY</code>, <code>RUNNING</code>, <code>UNHEALTHY</code>, or <code>TERMINATED</code> state. When you run RestoreServer, the server's EC2 instance is deleted, and a new EC2 instance is configured. RestoreServer maintains the existing server endpoint, so configuration management of the server's client devices (nodes) should continue to work. </p> <p>Restoring from a backup is performed by creating a new EC2 instance. If restoration is successful, and the server is in a <code>HEALTHY</code> state, AWS OpsWorks CM switches traffic over to the new instance. After restoration is finished, the old EC2 instance is maintained in a <code>Running</code> or <code>Stopped</code> state, but is eventually terminated.</p> <p> This operation is asynchronous. </p> <p> An <code>InvalidStateException</code> is thrown when the server is not in a valid state. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var restoreServer* = Call_RestoreServer_402656669(name: "restoreServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.RestoreServer",
    validator: validate_RestoreServer_402656670, base: "/",
    makeUrl: url_RestoreServer_402656671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMaintenance_402656684 = ref object of OpenApiRestCall_402656044
proc url_StartMaintenance_402656686(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMaintenance_402656685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Target")
  valid_402656687 = validateParameter(valid_402656687, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.StartMaintenance"))
  if valid_402656687 != nil:
    section.add "X-Amz-Target", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Security-Token", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Signature")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Signature", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Algorithm", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Date")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Date", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Credential")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Credential", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656696: Call_StartMaintenance_402656684;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Manually starts server maintenance. This command can be useful if an earlier maintenance attempt failed, and the underlying cause of maintenance failure has been resolved. The server is in an <code>UNDER_MAINTENANCE</code> state while maintenance is in progress. </p> <p> Maintenance can only be started on servers in <code>HEALTHY</code> and <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
                                                                                         ## 
  let valid = call_402656696.validator(path, query, header, formData, body, _)
  let scheme = call_402656696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656696.makeUrl(scheme.get, call_402656696.host, call_402656696.base,
                                   call_402656696.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656696, uri, valid, _)

proc call*(call_402656697: Call_StartMaintenance_402656684; body: JsonNode): Recallable =
  ## startMaintenance
  ## <p> Manually starts server maintenance. This command can be useful if an earlier maintenance attempt failed, and the underlying cause of maintenance failure has been resolved. The server is in an <code>UNDER_MAINTENANCE</code> state while maintenance is in progress. </p> <p> Maintenance can only be started on servers in <code>HEALTHY</code> and <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is thrown. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  result = call_402656697.call(nil, nil, nil, nil, body_402656698)

var startMaintenance* = Call_StartMaintenance_402656684(
    name: "startMaintenance", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.StartMaintenance",
    validator: validate_StartMaintenance_402656685, base: "/",
    makeUrl: url_StartMaintenance_402656686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656699 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656701(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402656700(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656702 = header.getOrDefault("X-Amz-Target")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.TagResource"))
  if valid_402656702 != nil:
    section.add "X-Amz-Target", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Security-Token", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Signature")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Signature", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Algorithm", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Date")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Date", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Credential")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Credential", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656711: Call_TagResource_402656699; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Applies tags to an AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise server, or to server backups.
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_TagResource_402656699; body: JsonNode): Recallable =
  ## tagResource
  ## Applies tags to an AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise server, or to server backups.
  ##   
                                                                                                                          ## body: JObject (required)
  var body_402656713 = newJObject()
  if body != nil:
    body_402656713 = body
  result = call_402656712.call(nil, nil, nil, nil, body_402656713)

var tagResource* = Call_TagResource_402656699(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.TagResource",
    validator: validate_TagResource_402656700, base: "/",
    makeUrl: url_TagResource_402656701, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656714 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656716(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402656715(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656717 = header.getOrDefault("X-Amz-Target")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.UntagResource"))
  if valid_402656717 != nil:
    section.add "X-Amz-Target", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656726: Call_UntagResource_402656714; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes specified tags from an AWS OpsWorks-CM server or backup.
                                                                                         ## 
  let valid = call_402656726.validator(path, query, header, formData, body, _)
  let scheme = call_402656726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656726.makeUrl(scheme.get, call_402656726.host, call_402656726.base,
                                   call_402656726.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656726, uri, valid, _)

proc call*(call_402656727: Call_UntagResource_402656714; body: JsonNode): Recallable =
  ## untagResource
  ## Removes specified tags from an AWS OpsWorks-CM server or backup.
  ##   body: JObject (required)
  var body_402656728 = newJObject()
  if body != nil:
    body_402656728 = body
  result = call_402656727.call(nil, nil, nil, nil, body_402656728)

var untagResource* = Call_UntagResource_402656714(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.UntagResource",
    validator: validate_UntagResource_402656715, base: "/",
    makeUrl: url_UntagResource_402656716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServer_402656729 = ref object of OpenApiRestCall_402656044
proc url_UpdateServer_402656731(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateServer_402656730(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656732 = header.getOrDefault("X-Amz-Target")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.UpdateServer"))
  if valid_402656732 != nil:
    section.add "X-Amz-Target", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656741: Call_UpdateServer_402656729; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Updates settings for a server. </p> <p> This operation is synchronous. </p>
                                                                                         ## 
  let valid = call_402656741.validator(path, query, header, formData, body, _)
  let scheme = call_402656741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656741.makeUrl(scheme.get, call_402656741.host, call_402656741.base,
                                   call_402656741.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656741, uri, valid, _)

proc call*(call_402656742: Call_UpdateServer_402656729; body: JsonNode): Recallable =
  ## updateServer
  ## <p> Updates settings for a server. </p> <p> This operation is synchronous. </p>
  ##   
                                                                                    ## body: JObject (required)
  var body_402656743 = newJObject()
  if body != nil:
    body_402656743 = body
  result = call_402656742.call(nil, nil, nil, nil, body_402656743)

var updateServer* = Call_UpdateServer_402656729(name: "updateServer",
    meth: HttpMethod.HttpPost, host: "opsworks-cm.amazonaws.com",
    route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.UpdateServer",
    validator: validate_UpdateServer_402656730, base: "/",
    makeUrl: url_UpdateServer_402656731, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServerEngineAttributes_402656744 = ref object of OpenApiRestCall_402656044
proc url_UpdateServerEngineAttributes_402656746(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateServerEngineAttributes_402656745(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656747 = header.getOrDefault("X-Amz-Target")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true, default = newJString(
      "OpsWorksCM_V2016_11_01.UpdateServerEngineAttributes"))
  if valid_402656747 != nil:
    section.add "X-Amz-Target", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Security-Token", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Signature")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Signature", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Algorithm", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Date")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Date", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Credential")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Credential", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656756: Call_UpdateServerEngineAttributes_402656744;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Updates engine-specific attributes on a specified server. The server enters the <code>MODIFYING</code> state when this operation is in progress. Only one update can occur at a time. You can use this command to reset a Chef server's public key (<code>CHEF_PIVOTAL_KEY</code>) or a Puppet server's admin password (<code>PUPPET_ADMIN_PASSWORD</code>). </p> <p> This operation is asynchronous. </p> <p> This operation can only be called for servers in <code>HEALTHY</code> or <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is raised. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_UpdateServerEngineAttributes_402656744;
           body: JsonNode): Recallable =
  ## updateServerEngineAttributes
  ## <p> Updates engine-specific attributes on a specified server. The server enters the <code>MODIFYING</code> state when this operation is in progress. Only one update can occur at a time. You can use this command to reset a Chef server's public key (<code>CHEF_PIVOTAL_KEY</code>) or a Puppet server's admin password (<code>PUPPET_ADMIN_PASSWORD</code>). </p> <p> This operation is asynchronous. </p> <p> This operation can only be called for servers in <code>HEALTHY</code> or <code>UNHEALTHY</code> states. Otherwise, an <code>InvalidStateException</code> is raised. A <code>ResourceNotFoundException</code> is thrown when the server does not exist. A <code>ValidationException</code> is raised when parameters of the request are not valid. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656758 = newJObject()
  if body != nil:
    body_402656758 = body
  result = call_402656757.call(nil, nil, nil, nil, body_402656758)

var updateServerEngineAttributes* = Call_UpdateServerEngineAttributes_402656744(
    name: "updateServerEngineAttributes", meth: HttpMethod.HttpPost,
    host: "opsworks-cm.amazonaws.com", route: "/#X-Amz-Target=OpsWorksCM_V2016_11_01.UpdateServerEngineAttributes",
    validator: validate_UpdateServerEngineAttributes_402656745, base: "/",
    makeUrl: url_UpdateServerEngineAttributes_402656746,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}