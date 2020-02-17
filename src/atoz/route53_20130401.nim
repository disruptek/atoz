
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Route 53
## version: 2013-04-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon Route 53 is a highly available and scalable Domain Name System (DNS) web service.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/route53/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "route53.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "route53.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "route53.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "route53.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "route53"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateVPCWithHostedZone_610996 = ref object of OpenApiRestCall_610658
proc url_AssociateVPCWithHostedZone_610998(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/associatevpc")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateVPCWithHostedZone_610997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : <p>The ID of the private hosted zone that you want to associate an Amazon VPC with.</p> <p>Note that you can't associate a VPC with a hosted zone that doesn't have an existing VPC association.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611124 = path.getOrDefault("Id")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "Id", valid_611124
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611125 = header.getOrDefault("X-Amz-Signature")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Signature", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Content-Sha256", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Date")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Date", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Credential")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Credential", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Security-Token")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Security-Token", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Algorithm")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Algorithm", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-SignedHeaders", valid_611131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611155: Call_AssociateVPCWithHostedZone_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ## 
  let valid = call_611155.validator(path, query, header, formData, body)
  let scheme = call_611155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611155.url(scheme.get, call_611155.host, call_611155.base,
                         call_611155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611155, url, valid)

proc call*(call_611226: Call_AssociateVPCWithHostedZone_610996; body: JsonNode;
          Id: string): Recallable =
  ## associateVPCWithHostedZone
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : <p>The ID of the private hosted zone that you want to associate an Amazon VPC with.</p> <p>Note that you can't associate a VPC with a hosted zone that doesn't have an existing VPC association.</p>
  var path_611227 = newJObject()
  var body_611229 = newJObject()
  if body != nil:
    body_611229 = body
  add(path_611227, "Id", newJString(Id))
  result = call_611226.call(path_611227, nil, nil, nil, body_611229)

var associateVPCWithHostedZone* = Call_AssociateVPCWithHostedZone_610996(
    name: "associateVPCWithHostedZone", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/associatevpc",
    validator: validate_AssociateVPCWithHostedZone_610997, base: "/",
    url: url_AssociateVPCWithHostedZone_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangeResourceRecordSets_611268 = ref object of OpenApiRestCall_610658
proc url_ChangeResourceRecordSets_611270(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/rrset/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ChangeResourceRecordSets_611269(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to change.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611271 = path.getOrDefault("Id")
  valid_611271 = validateParameter(valid_611271, JString, required = true,
                                 default = nil)
  if valid_611271 != nil:
    section.add "Id", valid_611271
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611272 = header.getOrDefault("X-Amz-Signature")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Signature", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Content-Sha256", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Date")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Date", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Credential")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Credential", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Security-Token")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Security-Token", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Algorithm")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Algorithm", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-SignedHeaders", valid_611278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611280: Call_ChangeResourceRecordSets_611268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_611280.validator(path, query, header, formData, body)
  let scheme = call_611280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611280.url(scheme.get, call_611280.host, call_611280.base,
                         call_611280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611280, url, valid)

proc call*(call_611281: Call_ChangeResourceRecordSets_611268; body: JsonNode;
          Id: string): Recallable =
  ## changeResourceRecordSets
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to change.
  var path_611282 = newJObject()
  var body_611283 = newJObject()
  if body != nil:
    body_611283 = body
  add(path_611282, "Id", newJString(Id))
  result = call_611281.call(path_611282, nil, nil, nil, body_611283)

var changeResourceRecordSets* = Call_ChangeResourceRecordSets_611268(
    name: "changeResourceRecordSets", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}/rrset/",
    validator: validate_ChangeResourceRecordSets_611269, base: "/",
    url: url_ChangeResourceRecordSets_611270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangeTagsForResource_611312 = ref object of OpenApiRestCall_610658
proc url_ChangeTagsForResource_611314(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceType" in path, "`ResourceType` is a required path parameter"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/tags/"),
               (kind: VariableSegment, value: "ResourceType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "ResourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ChangeTagsForResource_611313(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource for which you want to add, change, or delete tags.
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_611315 = path.getOrDefault("ResourceId")
  valid_611315 = validateParameter(valid_611315, JString, required = true,
                                 default = nil)
  if valid_611315 != nil:
    section.add "ResourceId", valid_611315
  var valid_611316 = path.getOrDefault("ResourceType")
  valid_611316 = validateParameter(valid_611316, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_611316 != nil:
    section.add "ResourceType", valid_611316
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611317 = header.getOrDefault("X-Amz-Signature")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Signature", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Content-Sha256", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Date")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Date", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Credential")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Credential", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Security-Token")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Security-Token", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-Algorithm")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Algorithm", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-SignedHeaders", valid_611323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611325: Call_ChangeTagsForResource_611312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_611325.validator(path, query, header, formData, body)
  let scheme = call_611325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611325.url(scheme.get, call_611325.host, call_611325.base,
                         call_611325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611325, url, valid)

proc call*(call_611326: Call_ChangeTagsForResource_611312; ResourceId: string;
          body: JsonNode; ResourceType: string = "healthcheck"): Recallable =
  ## changeTagsForResource
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceId: string (required)
  ##             : The ID of the resource for which you want to add, change, or delete tags.
  ##   ResourceType: string (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   body: JObject (required)
  var path_611327 = newJObject()
  var body_611328 = newJObject()
  add(path_611327, "ResourceId", newJString(ResourceId))
  add(path_611327, "ResourceType", newJString(ResourceType))
  if body != nil:
    body_611328 = body
  result = call_611326.call(path_611327, nil, nil, nil, body_611328)

var changeTagsForResource* = Call_ChangeTagsForResource_611312(
    name: "changeTagsForResource", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/tags/{ResourceType}/{ResourceId}",
    validator: validate_ChangeTagsForResource_611313, base: "/",
    url: url_ChangeTagsForResource_611314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611284 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611286(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceType" in path, "`ResourceType` is a required path parameter"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/tags/"),
               (kind: VariableSegment, value: "ResourceType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "ResourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_611285(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource for which you want to retrieve tags.
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_611287 = path.getOrDefault("ResourceId")
  valid_611287 = validateParameter(valid_611287, JString, required = true,
                                 default = nil)
  if valid_611287 != nil:
    section.add "ResourceId", valid_611287
  var valid_611301 = path.getOrDefault("ResourceType")
  valid_611301 = validateParameter(valid_611301, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_611301 != nil:
    section.add "ResourceType", valid_611301
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611302 = header.getOrDefault("X-Amz-Signature")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Signature", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Content-Sha256", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Date")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Date", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Credential")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Credential", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Security-Token")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Security-Token", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-Algorithm")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Algorithm", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-SignedHeaders", valid_611308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611309: Call_ListTagsForResource_611284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_611309.validator(path, query, header, formData, body)
  let scheme = call_611309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611309.url(scheme.get, call_611309.host, call_611309.base,
                         call_611309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611309, url, valid)

proc call*(call_611310: Call_ListTagsForResource_611284; ResourceId: string;
          ResourceType: string = "healthcheck"): Recallable =
  ## listTagsForResource
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceId: string (required)
  ##             : The ID of the resource for which you want to retrieve tags.
  ##   ResourceType: string (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  var path_611311 = newJObject()
  add(path_611311, "ResourceId", newJString(ResourceId))
  add(path_611311, "ResourceType", newJString(ResourceType))
  result = call_611310.call(path_611311, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611284(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/tags/{ResourceType}/{ResourceId}",
    validator: validate_ListTagsForResource_611285, base: "/",
    url: url_ListTagsForResource_611286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHealthCheck_611346 = ref object of OpenApiRestCall_610658
proc url_CreateHealthCheck_611348(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHealthCheck_611347(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611349 = header.getOrDefault("X-Amz-Signature")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Signature", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Content-Sha256", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Date")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Date", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Credential")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Credential", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Security-Token")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Security-Token", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Algorithm")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Algorithm", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-SignedHeaders", valid_611355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611357: Call_CreateHealthCheck_611346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
  ## 
  let valid = call_611357.validator(path, query, header, formData, body)
  let scheme = call_611357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611357.url(scheme.get, call_611357.host, call_611357.base,
                         call_611357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611357, url, valid)

proc call*(call_611358: Call_CreateHealthCheck_611346; body: JsonNode): Recallable =
  ## createHealthCheck
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_611359 = newJObject()
  if body != nil:
    body_611359 = body
  result = call_611358.call(nil, nil, nil, nil, body_611359)

var createHealthCheck* = Call_CreateHealthCheck_611346(name: "createHealthCheck",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck", validator: validate_CreateHealthCheck_611347,
    base: "/", url: url_CreateHealthCheck_611348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHealthChecks_611329 = ref object of OpenApiRestCall_610658
proc url_ListHealthChecks_611331(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHealthChecks_611330(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxItems: JString
  ##           : Pagination limit
  ##   maxitems: JString
  ##           : The maximum number of health checks that you want <code>ListHealthChecks</code> to return in response to the current request. Amazon Route 53 returns a maximum of 100 items. If you set <code>MaxItems</code> to a value greater than 100, Route 53 returns only the first 100 health checks. 
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more health checks. To get another group, submit another <code>ListHealthChecks</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first health check that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more health checks to get.</p>
  section = newJObject()
  var valid_611332 = query.getOrDefault("Marker")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "Marker", valid_611332
  var valid_611333 = query.getOrDefault("MaxItems")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "MaxItems", valid_611333
  var valid_611334 = query.getOrDefault("maxitems")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "maxitems", valid_611334
  var valid_611335 = query.getOrDefault("marker")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "marker", valid_611335
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611336 = header.getOrDefault("X-Amz-Signature")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Signature", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Content-Sha256", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Date")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Date", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Credential")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Credential", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Security-Token")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Security-Token", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Algorithm")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Algorithm", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-SignedHeaders", valid_611342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611343: Call_ListHealthChecks_611329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ## 
  let valid = call_611343.validator(path, query, header, formData, body)
  let scheme = call_611343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611343.url(scheme.get, call_611343.host, call_611343.base,
                         call_611343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611343, url, valid)

proc call*(call_611344: Call_ListHealthChecks_611329; Marker: string = "";
          MaxItems: string = ""; maxitems: string = ""; marker: string = ""): Recallable =
  ## listHealthChecks
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ##   Marker: string
  ##         : Pagination token
  ##   MaxItems: string
  ##           : Pagination limit
  ##   maxitems: string
  ##           : The maximum number of health checks that you want <code>ListHealthChecks</code> to return in response to the current request. Amazon Route 53 returns a maximum of 100 items. If you set <code>MaxItems</code> to a value greater than 100, Route 53 returns only the first 100 health checks. 
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more health checks. To get another group, submit another <code>ListHealthChecks</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first health check that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more health checks to get.</p>
  var query_611345 = newJObject()
  add(query_611345, "Marker", newJString(Marker))
  add(query_611345, "MaxItems", newJString(MaxItems))
  add(query_611345, "maxitems", newJString(maxitems))
  add(query_611345, "marker", newJString(marker))
  result = call_611344.call(nil, query_611345, nil, nil, nil)

var listHealthChecks* = Call_ListHealthChecks_611329(name: "listHealthChecks",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck", validator: validate_ListHealthChecks_611330,
    base: "/", url: url_ListHealthChecks_611331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHostedZone_611378 = ref object of OpenApiRestCall_610658
proc url_CreateHostedZone_611380(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHostedZone_611379(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611381 = header.getOrDefault("X-Amz-Signature")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Signature", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Content-Sha256", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Date")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Date", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Credential")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Credential", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Security-Token")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Security-Token", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Algorithm")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Algorithm", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-SignedHeaders", valid_611387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611389: Call_CreateHostedZone_611378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
  ## 
  let valid = call_611389.validator(path, query, header, formData, body)
  let scheme = call_611389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611389.url(scheme.get, call_611389.host, call_611389.base,
                         call_611389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611389, url, valid)

proc call*(call_611390: Call_CreateHostedZone_611378; body: JsonNode): Recallable =
  ## createHostedZone
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
  ##   body: JObject (required)
  var body_611391 = newJObject()
  if body != nil:
    body_611391 = body
  result = call_611390.call(nil, nil, nil, nil, body_611391)

var createHostedZone* = Call_CreateHostedZone_611378(name: "createHostedZone",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone", validator: validate_CreateHostedZone_611379,
    base: "/", url: url_CreateHostedZone_611380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHostedZones_611360 = ref object of OpenApiRestCall_610658
proc url_ListHostedZones_611362(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHostedZones_611361(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxItems: JString
  ##           : Pagination limit
  ##   maxitems: JString
  ##           : (Optional) The maximum number of hosted zones that you want Amazon Route 53 to return. If you have more than <code>maxitems</code> hosted zones, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>NextMarker</code> is the hosted zone ID of the first hosted zone that Route 53 will return if you submit another request.
  ##   delegationsetid: JString
  ##                  : If you're using reusable delegation sets and you want to list all of the hosted zones that are associated with a reusable delegation set, specify the ID of that reusable delegation set. 
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more hosted zones. To get more hosted zones, submit another <code>ListHostedZones</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first hosted zone that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more hosted zones to get.</p>
  section = newJObject()
  var valid_611363 = query.getOrDefault("Marker")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "Marker", valid_611363
  var valid_611364 = query.getOrDefault("MaxItems")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "MaxItems", valid_611364
  var valid_611365 = query.getOrDefault("maxitems")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "maxitems", valid_611365
  var valid_611366 = query.getOrDefault("delegationsetid")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "delegationsetid", valid_611366
  var valid_611367 = query.getOrDefault("marker")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "marker", valid_611367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611368 = header.getOrDefault("X-Amz-Signature")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Signature", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Content-Sha256", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Date")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Date", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Credential")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Credential", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Security-Token")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Security-Token", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Algorithm")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Algorithm", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-SignedHeaders", valid_611374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611375: Call_ListHostedZones_611360; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_611375.validator(path, query, header, formData, body)
  let scheme = call_611375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611375.url(scheme.get, call_611375.host, call_611375.base,
                         call_611375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611375, url, valid)

proc call*(call_611376: Call_ListHostedZones_611360; Marker: string = "";
          MaxItems: string = ""; maxitems: string = ""; delegationsetid: string = "";
          marker: string = ""): Recallable =
  ## listHostedZones
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ##   Marker: string
  ##         : Pagination token
  ##   MaxItems: string
  ##           : Pagination limit
  ##   maxitems: string
  ##           : (Optional) The maximum number of hosted zones that you want Amazon Route 53 to return. If you have more than <code>maxitems</code> hosted zones, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>NextMarker</code> is the hosted zone ID of the first hosted zone that Route 53 will return if you submit another request.
  ##   delegationsetid: string
  ##                  : If you're using reusable delegation sets and you want to list all of the hosted zones that are associated with a reusable delegation set, specify the ID of that reusable delegation set. 
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more hosted zones. To get more hosted zones, submit another <code>ListHostedZones</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first hosted zone that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more hosted zones to get.</p>
  var query_611377 = newJObject()
  add(query_611377, "Marker", newJString(Marker))
  add(query_611377, "MaxItems", newJString(MaxItems))
  add(query_611377, "maxitems", newJString(maxitems))
  add(query_611377, "delegationsetid", newJString(delegationsetid))
  add(query_611377, "marker", newJString(marker))
  result = call_611376.call(nil, query_611377, nil, nil, nil)

var listHostedZones* = Call_ListHostedZones_611360(name: "listHostedZones",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone", validator: validate_ListHostedZones_611361,
    base: "/", url: url_ListHostedZones_611362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQueryLoggingConfig_611408 = ref object of OpenApiRestCall_610658
proc url_CreateQueryLoggingConfig_611410(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateQueryLoggingConfig_611409(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611411 = header.getOrDefault("X-Amz-Signature")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Signature", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Content-Sha256", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Date")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Date", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Credential")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Credential", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Security-Token")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Security-Token", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Algorithm")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Algorithm", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-SignedHeaders", valid_611417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611419: Call_CreateQueryLoggingConfig_611408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
  ## 
  let valid = call_611419.validator(path, query, header, formData, body)
  let scheme = call_611419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611419.url(scheme.get, call_611419.host, call_611419.base,
                         call_611419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611419, url, valid)

proc call*(call_611420: Call_CreateQueryLoggingConfig_611408; body: JsonNode): Recallable =
  ## createQueryLoggingConfig
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
  ##   body: JObject (required)
  var body_611421 = newJObject()
  if body != nil:
    body_611421 = body
  result = call_611420.call(nil, nil, nil, nil, body_611421)

var createQueryLoggingConfig* = Call_CreateQueryLoggingConfig_611408(
    name: "createQueryLoggingConfig", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig",
    validator: validate_CreateQueryLoggingConfig_611409, base: "/",
    url: url_CreateQueryLoggingConfig_611410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueryLoggingConfigs_611392 = ref object of OpenApiRestCall_610658
proc url_ListQueryLoggingConfigs_611394(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListQueryLoggingConfigs_611393(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the configurations for DNS query logging that are associated with the current AWS account or the configuration that is associated with a specified hosted zone.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>. Additional information, including the format of DNS query logs, appears in <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nexttoken: JString
  ##            : <p>(Optional) If the current AWS account has more than <code>MaxResults</code> query logging configurations, use <code>NextToken</code> to get the second and subsequent pages of results.</p> <p>For the first <code>ListQueryLoggingConfigs</code> request, omit this value.</p> <p>For the second and subsequent requests, get the value of <code>NextToken</code> from the previous response and specify that value for <code>NextToken</code> in the request.</p>
  ##   maxresults: JString
  ##             : <p>(Optional) The maximum number of query logging configurations that you want Amazon Route 53 to return in response to the current request. If the current AWS account has more than <code>MaxResults</code> configurations, use the value of <a 
  ## href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ListQueryLoggingConfigs.html#API_ListQueryLoggingConfigs_RequestSyntax">NextToken</a> in the response to get the next page of results.</p> <p>If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 100 configurations.</p>
  ##   hostedzoneid: JString
  ##               : <p>(Optional) If you want to list the query logging configuration that is associated with a hosted zone, specify the ID in <code>HostedZoneId</code>. </p> <p>If you don't specify a hosted zone ID, <code>ListQueryLoggingConfigs</code> returns all of the configurations that are associated with the current AWS account.</p>
  section = newJObject()
  var valid_611395 = query.getOrDefault("nexttoken")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "nexttoken", valid_611395
  var valid_611396 = query.getOrDefault("maxresults")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "maxresults", valid_611396
  var valid_611397 = query.getOrDefault("hostedzoneid")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "hostedzoneid", valid_611397
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611398 = header.getOrDefault("X-Amz-Signature")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Signature", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Content-Sha256", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-Date")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Date", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Credential")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Credential", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-Security-Token")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-Security-Token", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-Algorithm")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-Algorithm", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-SignedHeaders", valid_611404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611405: Call_ListQueryLoggingConfigs_611392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the configurations for DNS query logging that are associated with the current AWS account or the configuration that is associated with a specified hosted zone.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>. Additional information, including the format of DNS query logs, appears in <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_611405.validator(path, query, header, formData, body)
  let scheme = call_611405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611405.url(scheme.get, call_611405.host, call_611405.base,
                         call_611405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611405, url, valid)

proc call*(call_611406: Call_ListQueryLoggingConfigs_611392;
          nexttoken: string = ""; maxresults: string = ""; hostedzoneid: string = ""): Recallable =
  ## listQueryLoggingConfigs
  ## <p>Lists the configurations for DNS query logging that are associated with the current AWS account or the configuration that is associated with a specified hosted zone.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>. Additional information, including the format of DNS query logs, appears in <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   nexttoken: string
  ##            : <p>(Optional) If the current AWS account has more than <code>MaxResults</code> query logging configurations, use <code>NextToken</code> to get the second and subsequent pages of results.</p> <p>For the first <code>ListQueryLoggingConfigs</code> request, omit this value.</p> <p>For the second and subsequent requests, get the value of <code>NextToken</code> from the previous response and specify that value for <code>NextToken</code> in the request.</p>
  ##   maxresults: string
  ##             : <p>(Optional) The maximum number of query logging configurations that you want Amazon Route 53 to return in response to the current request. If the current AWS account has more than <code>MaxResults</code> configurations, use the value of <a 
  ## href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ListQueryLoggingConfigs.html#API_ListQueryLoggingConfigs_RequestSyntax">NextToken</a> in the response to get the next page of results.</p> <p>If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 100 configurations.</p>
  ##   hostedzoneid: string
  ##               : <p>(Optional) If you want to list the query logging configuration that is associated with a hosted zone, specify the ID in <code>HostedZoneId</code>. </p> <p>If you don't specify a hosted zone ID, <code>ListQueryLoggingConfigs</code> returns all of the configurations that are associated with the current AWS account.</p>
  var query_611407 = newJObject()
  add(query_611407, "nexttoken", newJString(nexttoken))
  add(query_611407, "maxresults", newJString(maxresults))
  add(query_611407, "hostedzoneid", newJString(hostedzoneid))
  result = call_611406.call(nil, query_611407, nil, nil, nil)

var listQueryLoggingConfigs* = Call_ListQueryLoggingConfigs_611392(
    name: "listQueryLoggingConfigs", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig",
    validator: validate_ListQueryLoggingConfigs_611393, base: "/",
    url: url_ListQueryLoggingConfigs_611394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReusableDelegationSet_611437 = ref object of OpenApiRestCall_610658
proc url_CreateReusableDelegationSet_611439(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateReusableDelegationSet_611438(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611440 = header.getOrDefault("X-Amz-Signature")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Signature", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Content-Sha256", valid_611441
  var valid_611442 = header.getOrDefault("X-Amz-Date")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-Date", valid_611442
  var valid_611443 = header.getOrDefault("X-Amz-Credential")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-Credential", valid_611443
  var valid_611444 = header.getOrDefault("X-Amz-Security-Token")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Security-Token", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Algorithm")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Algorithm", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-SignedHeaders", valid_611446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611448: Call_CreateReusableDelegationSet_611437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
  ## 
  let valid = call_611448.validator(path, query, header, formData, body)
  let scheme = call_611448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611448.url(scheme.get, call_611448.host, call_611448.base,
                         call_611448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611448, url, valid)

proc call*(call_611449: Call_CreateReusableDelegationSet_611437; body: JsonNode): Recallable =
  ## createReusableDelegationSet
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
  ##   body: JObject (required)
  var body_611450 = newJObject()
  if body != nil:
    body_611450 = body
  result = call_611449.call(nil, nil, nil, nil, body_611450)

var createReusableDelegationSet* = Call_CreateReusableDelegationSet_611437(
    name: "createReusableDelegationSet", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset",
    validator: validate_CreateReusableDelegationSet_611438, base: "/",
    url: url_CreateReusableDelegationSet_611439,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReusableDelegationSets_611422 = ref object of OpenApiRestCall_610658
proc url_ListReusableDelegationSets_611424(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListReusableDelegationSets_611423(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxitems: JString
  ##           : The number of reusable delegation sets that you want Amazon Route 53 to return in the response to this request. If you specify a value greater than 100, Route 53 returns only the first 100 reusable delegation sets.
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more reusable delegation sets. To get another group, submit another <code>ListReusableDelegationSets</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first reusable delegation set that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more reusable delegation sets to get.</p>
  section = newJObject()
  var valid_611425 = query.getOrDefault("maxitems")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "maxitems", valid_611425
  var valid_611426 = query.getOrDefault("marker")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "marker", valid_611426
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611427 = header.getOrDefault("X-Amz-Signature")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Signature", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Content-Sha256", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Date")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Date", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Credential")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Credential", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Security-Token")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Security-Token", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Algorithm")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Algorithm", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-SignedHeaders", valid_611433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611434: Call_ListReusableDelegationSets_611422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ## 
  let valid = call_611434.validator(path, query, header, formData, body)
  let scheme = call_611434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611434.url(scheme.get, call_611434.host, call_611434.base,
                         call_611434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611434, url, valid)

proc call*(call_611435: Call_ListReusableDelegationSets_611422;
          maxitems: string = ""; marker: string = ""): Recallable =
  ## listReusableDelegationSets
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ##   maxitems: string
  ##           : The number of reusable delegation sets that you want Amazon Route 53 to return in the response to this request. If you specify a value greater than 100, Route 53 returns only the first 100 reusable delegation sets.
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more reusable delegation sets. To get another group, submit another <code>ListReusableDelegationSets</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first reusable delegation set that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more reusable delegation sets to get.</p>
  var query_611436 = newJObject()
  add(query_611436, "maxitems", newJString(maxitems))
  add(query_611436, "marker", newJString(marker))
  result = call_611435.call(nil, query_611436, nil, nil, nil)

var listReusableDelegationSets* = Call_ListReusableDelegationSets_611422(
    name: "listReusableDelegationSets", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset",
    validator: validate_ListReusableDelegationSets_611423, base: "/",
    url: url_ListReusableDelegationSets_611424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicy_611451 = ref object of OpenApiRestCall_610658
proc url_CreateTrafficPolicy_611453(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrafficPolicy_611452(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611454 = header.getOrDefault("X-Amz-Signature")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Signature", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Content-Sha256", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-Date")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Date", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-Credential")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Credential", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-Security-Token")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Security-Token", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Algorithm")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Algorithm", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-SignedHeaders", valid_611460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611462: Call_CreateTrafficPolicy_611451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
  ## 
  let valid = call_611462.validator(path, query, header, formData, body)
  let scheme = call_611462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611462.url(scheme.get, call_611462.host, call_611462.base,
                         call_611462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611462, url, valid)

proc call*(call_611463: Call_CreateTrafficPolicy_611451; body: JsonNode): Recallable =
  ## createTrafficPolicy
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
  ##   body: JObject (required)
  var body_611464 = newJObject()
  if body != nil:
    body_611464 = body
  result = call_611463.call(nil, nil, nil, nil, body_611464)

var createTrafficPolicy* = Call_CreateTrafficPolicy_611451(
    name: "createTrafficPolicy", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicy",
    validator: validate_CreateTrafficPolicy_611452, base: "/",
    url: url_CreateTrafficPolicy_611453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicyInstance_611465 = ref object of OpenApiRestCall_610658
proc url_CreateTrafficPolicyInstance_611467(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrafficPolicyInstance_611466(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611468 = header.getOrDefault("X-Amz-Signature")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Signature", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Content-Sha256", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Date")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Date", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-Credential")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Credential", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-Security-Token")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-Security-Token", valid_611472
  var valid_611473 = header.getOrDefault("X-Amz-Algorithm")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Algorithm", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-SignedHeaders", valid_611474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611476: Call_CreateTrafficPolicyInstance_611465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
  ## 
  let valid = call_611476.validator(path, query, header, formData, body)
  let scheme = call_611476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611476.url(scheme.get, call_611476.host, call_611476.base,
                         call_611476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611476, url, valid)

proc call*(call_611477: Call_CreateTrafficPolicyInstance_611465; body: JsonNode): Recallable =
  ## createTrafficPolicyInstance
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
  ##   body: JObject (required)
  var body_611478 = newJObject()
  if body != nil:
    body_611478 = body
  result = call_611477.call(nil, nil, nil, nil, body_611478)

var createTrafficPolicyInstance* = Call_CreateTrafficPolicyInstance_611465(
    name: "createTrafficPolicyInstance", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicyinstance",
    validator: validate_CreateTrafficPolicyInstance_611466, base: "/",
    url: url_CreateTrafficPolicyInstance_611467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicyVersion_611479 = ref object of OpenApiRestCall_610658
proc url_CreateTrafficPolicyVersion_611481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTrafficPolicyVersion_611480(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy for which you want to create a new version.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611482 = path.getOrDefault("Id")
  valid_611482 = validateParameter(valid_611482, JString, required = true,
                                 default = nil)
  if valid_611482 != nil:
    section.add "Id", valid_611482
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611483 = header.getOrDefault("X-Amz-Signature")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Signature", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Content-Sha256", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Date")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Date", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Credential")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Credential", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-Security-Token")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Security-Token", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-Algorithm")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-Algorithm", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-SignedHeaders", valid_611489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611491: Call_CreateTrafficPolicyVersion_611479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ## 
  let valid = call_611491.validator(path, query, header, formData, body)
  let scheme = call_611491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611491.url(scheme.get, call_611491.host, call_611491.base,
                         call_611491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611491, url, valid)

proc call*(call_611492: Call_CreateTrafficPolicyVersion_611479; body: JsonNode;
          Id: string): Recallable =
  ## createTrafficPolicyVersion
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the traffic policy for which you want to create a new version.
  var path_611493 = newJObject()
  var body_611494 = newJObject()
  if body != nil:
    body_611494 = body
  add(path_611493, "Id", newJString(Id))
  result = call_611492.call(path_611493, nil, nil, nil, body_611494)

var createTrafficPolicyVersion* = Call_CreateTrafficPolicyVersion_611479(
    name: "createTrafficPolicyVersion", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicy/{Id}",
    validator: validate_CreateTrafficPolicyVersion_611480, base: "/",
    url: url_CreateTrafficPolicyVersion_611481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCAssociationAuthorization_611512 = ref object of OpenApiRestCall_610658
proc url_CreateVPCAssociationAuthorization_611514(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/authorizevpcassociation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateVPCAssociationAuthorization_611513(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the private hosted zone that you want to authorize associating a VPC with.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611515 = path.getOrDefault("Id")
  valid_611515 = validateParameter(valid_611515, JString, required = true,
                                 default = nil)
  if valid_611515 != nil:
    section.add "Id", valid_611515
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611516 = header.getOrDefault("X-Amz-Signature")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Signature", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Content-Sha256", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Date")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Date", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Credential")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Credential", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Security-Token")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Security-Token", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Algorithm")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Algorithm", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-SignedHeaders", valid_611522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611524: Call_CreateVPCAssociationAuthorization_611512;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ## 
  let valid = call_611524.validator(path, query, header, formData, body)
  let scheme = call_611524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611524.url(scheme.get, call_611524.host, call_611524.base,
                         call_611524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611524, url, valid)

proc call*(call_611525: Call_CreateVPCAssociationAuthorization_611512;
          body: JsonNode; Id: string): Recallable =
  ## createVPCAssociationAuthorization
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the private hosted zone that you want to authorize associating a VPC with.
  var path_611526 = newJObject()
  var body_611527 = newJObject()
  if body != nil:
    body_611527 = body
  add(path_611526, "Id", newJString(Id))
  result = call_611525.call(path_611526, nil, nil, nil, body_611527)

var createVPCAssociationAuthorization* = Call_CreateVPCAssociationAuthorization_611512(
    name: "createVPCAssociationAuthorization", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/authorizevpcassociation",
    validator: validate_CreateVPCAssociationAuthorization_611513, base: "/",
    url: url_CreateVPCAssociationAuthorization_611514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCAssociationAuthorizations_611495 = ref object of OpenApiRestCall_610658
proc url_ListVPCAssociationAuthorizations_611497(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/authorizevpcassociation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVPCAssociationAuthorizations_611496(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone for which you want a list of VPCs that can be associated with the hosted zone.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611498 = path.getOrDefault("Id")
  valid_611498 = validateParameter(valid_611498, JString, required = true,
                                 default = nil)
  if valid_611498 != nil:
    section.add "Id", valid_611498
  result.add "path", section
  ## parameters in `query` object:
  ##   nexttoken: JString
  ##            :  <i>Optional</i>: If a response includes a <code>NextToken</code> element, there are more VPCs that can be associated with the specified hosted zone. To get the next page of results, submit another request, and include the value of <code>NextToken</code> from the response in the <code>nexttoken</code> parameter in another <code>ListVPCAssociationAuthorizations</code> request.
  ##   maxresults: JString
  ##             :  <i>Optional</i>: An integer that specifies the maximum number of VPCs that you want Amazon Route 53 to return. If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 50 VPCs per page.
  section = newJObject()
  var valid_611499 = query.getOrDefault("nexttoken")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "nexttoken", valid_611499
  var valid_611500 = query.getOrDefault("maxresults")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "maxresults", valid_611500
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611501 = header.getOrDefault("X-Amz-Signature")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Signature", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Content-Sha256", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Date")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Date", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Credential")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Credential", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Security-Token")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Security-Token", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-Algorithm")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Algorithm", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-SignedHeaders", valid_611507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611508: Call_ListVPCAssociationAuthorizations_611495;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ## 
  let valid = call_611508.validator(path, query, header, formData, body)
  let scheme = call_611508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611508.url(scheme.get, call_611508.host, call_611508.base,
                         call_611508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611508, url, valid)

proc call*(call_611509: Call_ListVPCAssociationAuthorizations_611495; Id: string;
          nexttoken: string = ""; maxresults: string = ""): Recallable =
  ## listVPCAssociationAuthorizations
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ##   nexttoken: string
  ##            :  <i>Optional</i>: If a response includes a <code>NextToken</code> element, there are more VPCs that can be associated with the specified hosted zone. To get the next page of results, submit another request, and include the value of <code>NextToken</code> from the response in the <code>nexttoken</code> parameter in another <code>ListVPCAssociationAuthorizations</code> request.
  ##   maxresults: string
  ##             :  <i>Optional</i>: An integer that specifies the maximum number of VPCs that you want Amazon Route 53 to return. If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 50 VPCs per page.
  ##   Id: string (required)
  ##     : The ID of the hosted zone for which you want a list of VPCs that can be associated with the hosted zone.
  var path_611510 = newJObject()
  var query_611511 = newJObject()
  add(query_611511, "nexttoken", newJString(nexttoken))
  add(query_611511, "maxresults", newJString(maxresults))
  add(path_611510, "Id", newJString(Id))
  result = call_611509.call(path_611510, query_611511, nil, nil, nil)

var listVPCAssociationAuthorizations* = Call_ListVPCAssociationAuthorizations_611495(
    name: "listVPCAssociationAuthorizations", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/authorizevpcassociation",
    validator: validate_ListVPCAssociationAuthorizations_611496, base: "/",
    url: url_ListVPCAssociationAuthorizations_611497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHealthCheck_611542 = ref object of OpenApiRestCall_610658
proc url_UpdateHealthCheck_611544(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateHealthCheck_611543(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : The ID for the health check for which you want detailed information. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_611545 = path.getOrDefault("HealthCheckId")
  valid_611545 = validateParameter(valid_611545, JString, required = true,
                                 default = nil)
  if valid_611545 != nil:
    section.add "HealthCheckId", valid_611545
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611546 = header.getOrDefault("X-Amz-Signature")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Signature", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Content-Sha256", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-Date")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Date", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Credential")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Credential", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-Security-Token")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Security-Token", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-Algorithm")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Algorithm", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-SignedHeaders", valid_611552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611554: Call_UpdateHealthCheck_611542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_611554.validator(path, query, header, formData, body)
  let scheme = call_611554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611554.url(scheme.get, call_611554.host, call_611554.base,
                         call_611554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611554, url, valid)

proc call*(call_611555: Call_UpdateHealthCheck_611542; HealthCheckId: string;
          body: JsonNode): Recallable =
  ## updateHealthCheck
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   HealthCheckId: string (required)
  ##                : The ID for the health check for which you want detailed information. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.
  ##   body: JObject (required)
  var path_611556 = newJObject()
  var body_611557 = newJObject()
  add(path_611556, "HealthCheckId", newJString(HealthCheckId))
  if body != nil:
    body_611557 = body
  result = call_611555.call(path_611556, nil, nil, nil, body_611557)

var updateHealthCheck* = Call_UpdateHealthCheck_611542(name: "updateHealthCheck",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_UpdateHealthCheck_611543, base: "/",
    url: url_UpdateHealthCheck_611544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheck_611528 = ref object of OpenApiRestCall_610658
proc url_GetHealthCheck_611530(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHealthCheck_611529(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about a specified health check.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : The identifier that Amazon Route 53 assigned to the health check when you created it. When you add or update a resource record set, you use this value to specify which health check to use. The value can be up to 64 characters long.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_611531 = path.getOrDefault("HealthCheckId")
  valid_611531 = validateParameter(valid_611531, JString, required = true,
                                 default = nil)
  if valid_611531 != nil:
    section.add "HealthCheckId", valid_611531
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611532 = header.getOrDefault("X-Amz-Signature")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Signature", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Content-Sha256", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-Date")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Date", valid_611534
  var valid_611535 = header.getOrDefault("X-Amz-Credential")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-Credential", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-Security-Token")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Security-Token", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Algorithm")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Algorithm", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-SignedHeaders", valid_611538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611539: Call_GetHealthCheck_611528; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified health check.
  ## 
  let valid = call_611539.validator(path, query, header, formData, body)
  let scheme = call_611539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611539.url(scheme.get, call_611539.host, call_611539.base,
                         call_611539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611539, url, valid)

proc call*(call_611540: Call_GetHealthCheck_611528; HealthCheckId: string): Recallable =
  ## getHealthCheck
  ## Gets information about a specified health check.
  ##   HealthCheckId: string (required)
  ##                : The identifier that Amazon Route 53 assigned to the health check when you created it. When you add or update a resource record set, you use this value to specify which health check to use. The value can be up to 64 characters long.
  var path_611541 = newJObject()
  add(path_611541, "HealthCheckId", newJString(HealthCheckId))
  result = call_611540.call(path_611541, nil, nil, nil, nil)

var getHealthCheck* = Call_GetHealthCheck_611528(name: "getHealthCheck",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_GetHealthCheck_611529, base: "/", url: url_GetHealthCheck_611530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHealthCheck_611558 = ref object of OpenApiRestCall_610658
proc url_DeleteHealthCheck_611560(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteHealthCheck_611559(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : The ID of the health check that you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_611561 = path.getOrDefault("HealthCheckId")
  valid_611561 = validateParameter(valid_611561, JString, required = true,
                                 default = nil)
  if valid_611561 != nil:
    section.add "HealthCheckId", valid_611561
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611562 = header.getOrDefault("X-Amz-Signature")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Signature", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-Content-Sha256", valid_611563
  var valid_611564 = header.getOrDefault("X-Amz-Date")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Date", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-Credential")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Credential", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Security-Token")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Security-Token", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Algorithm")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Algorithm", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-SignedHeaders", valid_611568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611569: Call_DeleteHealthCheck_611558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  let valid = call_611569.validator(path, query, header, formData, body)
  let scheme = call_611569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611569.url(scheme.get, call_611569.host, call_611569.base,
                         call_611569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611569, url, valid)

proc call*(call_611570: Call_DeleteHealthCheck_611558; HealthCheckId: string): Recallable =
  ## deleteHealthCheck
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ##   HealthCheckId: string (required)
  ##                : The ID of the health check that you want to delete.
  var path_611571 = newJObject()
  add(path_611571, "HealthCheckId", newJString(HealthCheckId))
  result = call_611570.call(path_611571, nil, nil, nil, nil)

var deleteHealthCheck* = Call_DeleteHealthCheck_611558(name: "deleteHealthCheck",
    meth: HttpMethod.HttpDelete, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_DeleteHealthCheck_611559, base: "/",
    url: url_DeleteHealthCheck_611560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHostedZoneComment_611586 = ref object of OpenApiRestCall_610658
proc url_UpdateHostedZoneComment_611588(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateHostedZoneComment_611587(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the comment for a specified hosted zone.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID for the hosted zone that you want to update the comment for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611589 = path.getOrDefault("Id")
  valid_611589 = validateParameter(valid_611589, JString, required = true,
                                 default = nil)
  if valid_611589 != nil:
    section.add "Id", valid_611589
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611590 = header.getOrDefault("X-Amz-Signature")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Signature", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Content-Sha256", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Date")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Date", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Credential")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Credential", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-Security-Token")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Security-Token", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-Algorithm")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Algorithm", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-SignedHeaders", valid_611596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611598: Call_UpdateHostedZoneComment_611586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the comment for a specified hosted zone.
  ## 
  let valid = call_611598.validator(path, query, header, formData, body)
  let scheme = call_611598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611598.url(scheme.get, call_611598.host, call_611598.base,
                         call_611598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611598, url, valid)

proc call*(call_611599: Call_UpdateHostedZoneComment_611586; body: JsonNode;
          Id: string): Recallable =
  ## updateHostedZoneComment
  ## Updates the comment for a specified hosted zone.
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID for the hosted zone that you want to update the comment for.
  var path_611600 = newJObject()
  var body_611601 = newJObject()
  if body != nil:
    body_611601 = body
  add(path_611600, "Id", newJString(Id))
  result = call_611599.call(path_611600, nil, nil, nil, body_611601)

var updateHostedZoneComment* = Call_UpdateHostedZoneComment_611586(
    name: "updateHostedZoneComment", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}",
    validator: validate_UpdateHostedZoneComment_611587, base: "/",
    url: url_UpdateHostedZoneComment_611588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZone_611572 = ref object of OpenApiRestCall_610658
proc url_GetHostedZone_611574(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHostedZone_611573(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611575 = path.getOrDefault("Id")
  valid_611575 = validateParameter(valid_611575, JString, required = true,
                                 default = nil)
  if valid_611575 != nil:
    section.add "Id", valid_611575
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611576 = header.getOrDefault("X-Amz-Signature")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "X-Amz-Signature", valid_611576
  var valid_611577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "X-Amz-Content-Sha256", valid_611577
  var valid_611578 = header.getOrDefault("X-Amz-Date")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "X-Amz-Date", valid_611578
  var valid_611579 = header.getOrDefault("X-Amz-Credential")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Credential", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-Security-Token")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Security-Token", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-Algorithm")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Algorithm", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-SignedHeaders", valid_611582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611583: Call_GetHostedZone_611572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ## 
  let valid = call_611583.validator(path, query, header, formData, body)
  let scheme = call_611583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611583.url(scheme.get, call_611583.host, call_611583.base,
                         call_611583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611583, url, valid)

proc call*(call_611584: Call_GetHostedZone_611572; Id: string): Recallable =
  ## getHostedZone
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ##   Id: string (required)
  ##     : The ID of the hosted zone that you want to get information about.
  var path_611585 = newJObject()
  add(path_611585, "Id", newJString(Id))
  result = call_611584.call(path_611585, nil, nil, nil, nil)

var getHostedZone* = Call_GetHostedZone_611572(name: "getHostedZone",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}", validator: validate_GetHostedZone_611573,
    base: "/", url: url_GetHostedZone_611574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHostedZone_611602 = ref object of OpenApiRestCall_610658
proc url_DeleteHostedZone_611604(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteHostedZone_611603(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611605 = path.getOrDefault("Id")
  valid_611605 = validateParameter(valid_611605, JString, required = true,
                                 default = nil)
  if valid_611605 != nil:
    section.add "Id", valid_611605
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611606 = header.getOrDefault("X-Amz-Signature")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Signature", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-Content-Sha256", valid_611607
  var valid_611608 = header.getOrDefault("X-Amz-Date")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-Date", valid_611608
  var valid_611609 = header.getOrDefault("X-Amz-Credential")
  valid_611609 = validateParameter(valid_611609, JString, required = false,
                                 default = nil)
  if valid_611609 != nil:
    section.add "X-Amz-Credential", valid_611609
  var valid_611610 = header.getOrDefault("X-Amz-Security-Token")
  valid_611610 = validateParameter(valid_611610, JString, required = false,
                                 default = nil)
  if valid_611610 != nil:
    section.add "X-Amz-Security-Token", valid_611610
  var valid_611611 = header.getOrDefault("X-Amz-Algorithm")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "X-Amz-Algorithm", valid_611611
  var valid_611612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "X-Amz-SignedHeaders", valid_611612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611613: Call_DeleteHostedZone_611602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ## 
  let valid = call_611613.validator(path, query, header, formData, body)
  let scheme = call_611613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611613.url(scheme.get, call_611613.host, call_611613.base,
                         call_611613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611613, url, valid)

proc call*(call_611614: Call_DeleteHostedZone_611602; Id: string): Recallable =
  ## deleteHostedZone
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the hosted zone you want to delete.
  var path_611615 = newJObject()
  add(path_611615, "Id", newJString(Id))
  result = call_611614.call(path_611615, nil, nil, nil, nil)

var deleteHostedZone* = Call_DeleteHostedZone_611602(name: "deleteHostedZone",
    meth: HttpMethod.HttpDelete, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}", validator: validate_DeleteHostedZone_611603,
    base: "/", url: url_DeleteHostedZone_611604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryLoggingConfig_611616 = ref object of OpenApiRestCall_610658
proc url_GetQueryLoggingConfig_611618(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/queryloggingconfig/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetQueryLoggingConfig_611617(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration for DNS query logging that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611619 = path.getOrDefault("Id")
  valid_611619 = validateParameter(valid_611619, JString, required = true,
                                 default = nil)
  if valid_611619 != nil:
    section.add "Id", valid_611619
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611620 = header.getOrDefault("X-Amz-Signature")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Signature", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Content-Sha256", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-Date")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-Date", valid_611622
  var valid_611623 = header.getOrDefault("X-Amz-Credential")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-Credential", valid_611623
  var valid_611624 = header.getOrDefault("X-Amz-Security-Token")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Security-Token", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-Algorithm")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Algorithm", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-SignedHeaders", valid_611626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611627: Call_GetQueryLoggingConfig_611616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ## 
  let valid = call_611627.validator(path, query, header, formData, body)
  let scheme = call_611627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611627.url(scheme.get, call_611627.host, call_611627.base,
                         call_611627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611627, url, valid)

proc call*(call_611628: Call_GetQueryLoggingConfig_611616; Id: string): Recallable =
  ## getQueryLoggingConfig
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the configuration for DNS query logging that you want to get information about.
  var path_611629 = newJObject()
  add(path_611629, "Id", newJString(Id))
  result = call_611628.call(path_611629, nil, nil, nil, nil)

var getQueryLoggingConfig* = Call_GetQueryLoggingConfig_611616(
    name: "getQueryLoggingConfig", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig/{Id}",
    validator: validate_GetQueryLoggingConfig_611617, base: "/",
    url: url_GetQueryLoggingConfig_611618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQueryLoggingConfig_611630 = ref object of OpenApiRestCall_610658
proc url_DeleteQueryLoggingConfig_611632(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/queryloggingconfig/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteQueryLoggingConfig_611631(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration that you want to delete. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611633 = path.getOrDefault("Id")
  valid_611633 = validateParameter(valid_611633, JString, required = true,
                                 default = nil)
  if valid_611633 != nil:
    section.add "Id", valid_611633
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611634 = header.getOrDefault("X-Amz-Signature")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Signature", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Content-Sha256", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Date")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Date", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Credential")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Credential", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Security-Token")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Security-Token", valid_611638
  var valid_611639 = header.getOrDefault("X-Amz-Algorithm")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-Algorithm", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-SignedHeaders", valid_611640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611641: Call_DeleteQueryLoggingConfig_611630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ## 
  let valid = call_611641.validator(path, query, header, formData, body)
  let scheme = call_611641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611641.url(scheme.get, call_611641.host, call_611641.base,
                         call_611641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611641, url, valid)

proc call*(call_611642: Call_DeleteQueryLoggingConfig_611630; Id: string): Recallable =
  ## deleteQueryLoggingConfig
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the configuration that you want to delete. 
  var path_611643 = newJObject()
  add(path_611643, "Id", newJString(Id))
  result = call_611642.call(path_611643, nil, nil, nil, nil)

var deleteQueryLoggingConfig* = Call_DeleteQueryLoggingConfig_611630(
    name: "deleteQueryLoggingConfig", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig/{Id}",
    validator: validate_DeleteQueryLoggingConfig_611631, base: "/",
    url: url_DeleteQueryLoggingConfig_611632, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReusableDelegationSet_611644 = ref object of OpenApiRestCall_610658
proc url_GetReusableDelegationSet_611646(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/delegationset/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetReusableDelegationSet_611645(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the reusable delegation set that you want to get a list of name servers for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611647 = path.getOrDefault("Id")
  valid_611647 = validateParameter(valid_611647, JString, required = true,
                                 default = nil)
  if valid_611647 != nil:
    section.add "Id", valid_611647
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611648 = header.getOrDefault("X-Amz-Signature")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Signature", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Content-Sha256", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-Date")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-Date", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Credential")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Credential", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Security-Token")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Security-Token", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Algorithm")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Algorithm", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-SignedHeaders", valid_611654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611655: Call_GetReusableDelegationSet_611644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ## 
  let valid = call_611655.validator(path, query, header, formData, body)
  let scheme = call_611655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611655.url(scheme.get, call_611655.host, call_611655.base,
                         call_611655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611655, url, valid)

proc call*(call_611656: Call_GetReusableDelegationSet_611644; Id: string): Recallable =
  ## getReusableDelegationSet
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ##   Id: string (required)
  ##     : The ID of the reusable delegation set that you want to get a list of name servers for.
  var path_611657 = newJObject()
  add(path_611657, "Id", newJString(Id))
  result = call_611656.call(path_611657, nil, nil, nil, nil)

var getReusableDelegationSet* = Call_GetReusableDelegationSet_611644(
    name: "getReusableDelegationSet", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset/{Id}",
    validator: validate_GetReusableDelegationSet_611645, base: "/",
    url: url_GetReusableDelegationSet_611646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReusableDelegationSet_611658 = ref object of OpenApiRestCall_610658
proc url_DeleteReusableDelegationSet_611660(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/delegationset/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteReusableDelegationSet_611659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the reusable delegation set that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611661 = path.getOrDefault("Id")
  valid_611661 = validateParameter(valid_611661, JString, required = true,
                                 default = nil)
  if valid_611661 != nil:
    section.add "Id", valid_611661
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611662 = header.getOrDefault("X-Amz-Signature")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-Signature", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Content-Sha256", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Date")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Date", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-Credential")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Credential", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Security-Token")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Security-Token", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Algorithm")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Algorithm", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-SignedHeaders", valid_611668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611669: Call_DeleteReusableDelegationSet_611658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ## 
  let valid = call_611669.validator(path, query, header, formData, body)
  let scheme = call_611669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611669.url(scheme.get, call_611669.host, call_611669.base,
                         call_611669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611669, url, valid)

proc call*(call_611670: Call_DeleteReusableDelegationSet_611658; Id: string): Recallable =
  ## deleteReusableDelegationSet
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ##   Id: string (required)
  ##     : The ID of the reusable delegation set that you want to delete.
  var path_611671 = newJObject()
  add(path_611671, "Id", newJString(Id))
  result = call_611670.call(path_611671, nil, nil, nil, nil)

var deleteReusableDelegationSet* = Call_DeleteReusableDelegationSet_611658(
    name: "deleteReusableDelegationSet", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset/{Id}",
    validator: validate_DeleteReusableDelegationSet_611659, base: "/",
    url: url_DeleteReusableDelegationSet_611660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrafficPolicyComment_611687 = ref object of OpenApiRestCall_610658
proc url_UpdateTrafficPolicyComment_611689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Version" in path, "`Version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTrafficPolicyComment_611688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the comment for a specified traffic policy version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Version: JInt (required)
  ##          : The value of <code>Version</code> for the traffic policy that you want to update the comment for.
  ##   Id: JString (required)
  ##     : The value of <code>Id</code> for the traffic policy that you want to update the comment for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Version` field"
  var valid_611690 = path.getOrDefault("Version")
  valid_611690 = validateParameter(valid_611690, JInt, required = true, default = nil)
  if valid_611690 != nil:
    section.add "Version", valid_611690
  var valid_611691 = path.getOrDefault("Id")
  valid_611691 = validateParameter(valid_611691, JString, required = true,
                                 default = nil)
  if valid_611691 != nil:
    section.add "Id", valid_611691
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611692 = header.getOrDefault("X-Amz-Signature")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-Signature", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Content-Sha256", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Date")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Date", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-Credential")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-Credential", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-Security-Token")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Security-Token", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Algorithm")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Algorithm", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-SignedHeaders", valid_611698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611700: Call_UpdateTrafficPolicyComment_611687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the comment for a specified traffic policy version.
  ## 
  let valid = call_611700.validator(path, query, header, formData, body)
  let scheme = call_611700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611700.url(scheme.get, call_611700.host, call_611700.base,
                         call_611700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611700, url, valid)

proc call*(call_611701: Call_UpdateTrafficPolicyComment_611687; Version: int;
          body: JsonNode; Id: string): Recallable =
  ## updateTrafficPolicyComment
  ## Updates the comment for a specified traffic policy version.
  ##   Version: int (required)
  ##          : The value of <code>Version</code> for the traffic policy that you want to update the comment for.
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The value of <code>Id</code> for the traffic policy that you want to update the comment for.
  var path_611702 = newJObject()
  var body_611703 = newJObject()
  add(path_611702, "Version", newJInt(Version))
  if body != nil:
    body_611703 = body
  add(path_611702, "Id", newJString(Id))
  result = call_611701.call(path_611702, nil, nil, nil, body_611703)

var updateTrafficPolicyComment* = Call_UpdateTrafficPolicyComment_611687(
    name: "updateTrafficPolicyComment", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_UpdateTrafficPolicyComment_611688, base: "/",
    url: url_UpdateTrafficPolicyComment_611689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicy_611672 = ref object of OpenApiRestCall_610658
proc url_GetTrafficPolicy_611674(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Version" in path, "`Version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTrafficPolicy_611673(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets information about a specific traffic policy version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Version: JInt (required)
  ##          : The version number of the traffic policy that you want to get information about.
  ##   Id: JString (required)
  ##     : The ID of the traffic policy that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Version` field"
  var valid_611675 = path.getOrDefault("Version")
  valid_611675 = validateParameter(valid_611675, JInt, required = true, default = nil)
  if valid_611675 != nil:
    section.add "Version", valid_611675
  var valid_611676 = path.getOrDefault("Id")
  valid_611676 = validateParameter(valid_611676, JString, required = true,
                                 default = nil)
  if valid_611676 != nil:
    section.add "Id", valid_611676
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611677 = header.getOrDefault("X-Amz-Signature")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-Signature", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Content-Sha256", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Date")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Date", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-Credential")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-Credential", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Security-Token")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Security-Token", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Algorithm")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Algorithm", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-SignedHeaders", valid_611683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611684: Call_GetTrafficPolicy_611672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific traffic policy version.
  ## 
  let valid = call_611684.validator(path, query, header, formData, body)
  let scheme = call_611684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611684.url(scheme.get, call_611684.host, call_611684.base,
                         call_611684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611684, url, valid)

proc call*(call_611685: Call_GetTrafficPolicy_611672; Version: int; Id: string): Recallable =
  ## getTrafficPolicy
  ## Gets information about a specific traffic policy version.
  ##   Version: int (required)
  ##          : The version number of the traffic policy that you want to get information about.
  ##   Id: string (required)
  ##     : The ID of the traffic policy that you want to get information about.
  var path_611686 = newJObject()
  add(path_611686, "Version", newJInt(Version))
  add(path_611686, "Id", newJString(Id))
  result = call_611685.call(path_611686, nil, nil, nil, nil)

var getTrafficPolicy* = Call_GetTrafficPolicy_611672(name: "getTrafficPolicy",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_GetTrafficPolicy_611673, base: "/",
    url: url_GetTrafficPolicy_611674, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrafficPolicy_611704 = ref object of OpenApiRestCall_610658
proc url_DeleteTrafficPolicy_611706(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Version" in path, "`Version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTrafficPolicy_611705(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a traffic policy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Version: JInt (required)
  ##          : The version number of the traffic policy that you want to delete.
  ##   Id: JString (required)
  ##     : The ID of the traffic policy that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Version` field"
  var valid_611707 = path.getOrDefault("Version")
  valid_611707 = validateParameter(valid_611707, JInt, required = true, default = nil)
  if valid_611707 != nil:
    section.add "Version", valid_611707
  var valid_611708 = path.getOrDefault("Id")
  valid_611708 = validateParameter(valid_611708, JString, required = true,
                                 default = nil)
  if valid_611708 != nil:
    section.add "Id", valid_611708
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611709 = header.getOrDefault("X-Amz-Signature")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Signature", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Content-Sha256", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Date")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Date", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Credential")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Credential", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-Security-Token")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Security-Token", valid_611713
  var valid_611714 = header.getOrDefault("X-Amz-Algorithm")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-Algorithm", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-SignedHeaders", valid_611715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611716: Call_DeleteTrafficPolicy_611704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a traffic policy.
  ## 
  let valid = call_611716.validator(path, query, header, formData, body)
  let scheme = call_611716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611716.url(scheme.get, call_611716.host, call_611716.base,
                         call_611716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611716, url, valid)

proc call*(call_611717: Call_DeleteTrafficPolicy_611704; Version: int; Id: string): Recallable =
  ## deleteTrafficPolicy
  ## Deletes a traffic policy.
  ##   Version: int (required)
  ##          : The version number of the traffic policy that you want to delete.
  ##   Id: string (required)
  ##     : The ID of the traffic policy that you want to delete.
  var path_611718 = newJObject()
  add(path_611718, "Version", newJInt(Version))
  add(path_611718, "Id", newJString(Id))
  result = call_611717.call(path_611718, nil, nil, nil, nil)

var deleteTrafficPolicy* = Call_DeleteTrafficPolicy_611704(
    name: "deleteTrafficPolicy", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_DeleteTrafficPolicy_611705, base: "/",
    url: url_DeleteTrafficPolicy_611706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrafficPolicyInstance_611733 = ref object of OpenApiRestCall_610658
proc url_UpdateTrafficPolicyInstance_611735(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicyinstance/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTrafficPolicyInstance_611734(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy instance that you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611736 = path.getOrDefault("Id")
  valid_611736 = validateParameter(valid_611736, JString, required = true,
                                 default = nil)
  if valid_611736 != nil:
    section.add "Id", valid_611736
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611737 = header.getOrDefault("X-Amz-Signature")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-Signature", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-Content-Sha256", valid_611738
  var valid_611739 = header.getOrDefault("X-Amz-Date")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Date", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-Credential")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Credential", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Security-Token")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Security-Token", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Algorithm")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Algorithm", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-SignedHeaders", valid_611743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611745: Call_UpdateTrafficPolicyInstance_611733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ## 
  let valid = call_611745.validator(path, query, header, formData, body)
  let scheme = call_611745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611745.url(scheme.get, call_611745.host, call_611745.base,
                         call_611745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611745, url, valid)

proc call*(call_611746: Call_UpdateTrafficPolicyInstance_611733; body: JsonNode;
          Id: string): Recallable =
  ## updateTrafficPolicyInstance
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the traffic policy instance that you want to update.
  var path_611747 = newJObject()
  var body_611748 = newJObject()
  if body != nil:
    body_611748 = body
  add(path_611747, "Id", newJString(Id))
  result = call_611746.call(path_611747, nil, nil, nil, body_611748)

var updateTrafficPolicyInstance* = Call_UpdateTrafficPolicyInstance_611733(
    name: "updateTrafficPolicyInstance", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_UpdateTrafficPolicyInstance_611734, base: "/",
    url: url_UpdateTrafficPolicyInstance_611735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicyInstance_611719 = ref object of OpenApiRestCall_610658
proc url_GetTrafficPolicyInstance_611721(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicyinstance/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTrafficPolicyInstance_611720(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy instance that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611722 = path.getOrDefault("Id")
  valid_611722 = validateParameter(valid_611722, JString, required = true,
                                 default = nil)
  if valid_611722 != nil:
    section.add "Id", valid_611722
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611723 = header.getOrDefault("X-Amz-Signature")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Signature", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Content-Sha256", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-Date")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Date", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Credential")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Credential", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Security-Token")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Security-Token", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Algorithm")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Algorithm", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-SignedHeaders", valid_611729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611730: Call_GetTrafficPolicyInstance_611719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  let valid = call_611730.validator(path, query, header, formData, body)
  let scheme = call_611730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611730.url(scheme.get, call_611730.host, call_611730.base,
                         call_611730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611730, url, valid)

proc call*(call_611731: Call_GetTrafficPolicyInstance_611719; Id: string): Recallable =
  ## getTrafficPolicyInstance
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ##   Id: string (required)
  ##     : The ID of the traffic policy instance that you want to get information about.
  var path_611732 = newJObject()
  add(path_611732, "Id", newJString(Id))
  result = call_611731.call(path_611732, nil, nil, nil, nil)

var getTrafficPolicyInstance* = Call_GetTrafficPolicyInstance_611719(
    name: "getTrafficPolicyInstance", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_GetTrafficPolicyInstance_611720, base: "/",
    url: url_GetTrafficPolicyInstance_611721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrafficPolicyInstance_611749 = ref object of OpenApiRestCall_610658
proc url_DeleteTrafficPolicyInstance_611751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicyinstance/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTrafficPolicyInstance_611750(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : <p>The ID of the traffic policy instance that you want to delete. </p> <important> <p>When you delete a traffic policy instance, Amazon Route 53 also deletes all of the resource record sets that were created when you created the traffic policy instance.</p> </important>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611752 = path.getOrDefault("Id")
  valid_611752 = validateParameter(valid_611752, JString, required = true,
                                 default = nil)
  if valid_611752 != nil:
    section.add "Id", valid_611752
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611753 = header.getOrDefault("X-Amz-Signature")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-Signature", valid_611753
  var valid_611754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611754 = validateParameter(valid_611754, JString, required = false,
                                 default = nil)
  if valid_611754 != nil:
    section.add "X-Amz-Content-Sha256", valid_611754
  var valid_611755 = header.getOrDefault("X-Amz-Date")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-Date", valid_611755
  var valid_611756 = header.getOrDefault("X-Amz-Credential")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Credential", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Security-Token")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Security-Token", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Algorithm")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Algorithm", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-SignedHeaders", valid_611759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611760: Call_DeleteTrafficPolicyInstance_611749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  let valid = call_611760.validator(path, query, header, formData, body)
  let scheme = call_611760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611760.url(scheme.get, call_611760.host, call_611760.base,
                         call_611760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611760, url, valid)

proc call*(call_611761: Call_DeleteTrafficPolicyInstance_611749; Id: string): Recallable =
  ## deleteTrafficPolicyInstance
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ##   Id: string (required)
  ##     : <p>The ID of the traffic policy instance that you want to delete. </p> <important> <p>When you delete a traffic policy instance, Amazon Route 53 also deletes all of the resource record sets that were created when you created the traffic policy instance.</p> </important>
  var path_611762 = newJObject()
  add(path_611762, "Id", newJString(Id))
  result = call_611761.call(path_611762, nil, nil, nil, nil)

var deleteTrafficPolicyInstance* = Call_DeleteTrafficPolicyInstance_611749(
    name: "deleteTrafficPolicyInstance", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_DeleteTrafficPolicyInstance_611750, base: "/",
    url: url_DeleteTrafficPolicyInstance_611751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCAssociationAuthorization_611763 = ref object of OpenApiRestCall_610658
proc url_DeleteVPCAssociationAuthorization_611765(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/deauthorizevpcassociation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVPCAssociationAuthorization_611764(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : When removing authorization to associate a VPC that was created by one AWS account with a hosted zone that was created with a different AWS account, the ID of the hosted zone.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611766 = path.getOrDefault("Id")
  valid_611766 = validateParameter(valid_611766, JString, required = true,
                                 default = nil)
  if valid_611766 != nil:
    section.add "Id", valid_611766
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611767 = header.getOrDefault("X-Amz-Signature")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Signature", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-Content-Sha256", valid_611768
  var valid_611769 = header.getOrDefault("X-Amz-Date")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Date", valid_611769
  var valid_611770 = header.getOrDefault("X-Amz-Credential")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-Credential", valid_611770
  var valid_611771 = header.getOrDefault("X-Amz-Security-Token")
  valid_611771 = validateParameter(valid_611771, JString, required = false,
                                 default = nil)
  if valid_611771 != nil:
    section.add "X-Amz-Security-Token", valid_611771
  var valid_611772 = header.getOrDefault("X-Amz-Algorithm")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Algorithm", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-SignedHeaders", valid_611773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611775: Call_DeleteVPCAssociationAuthorization_611763;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ## 
  let valid = call_611775.validator(path, query, header, formData, body)
  let scheme = call_611775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611775.url(scheme.get, call_611775.host, call_611775.base,
                         call_611775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611775, url, valid)

proc call*(call_611776: Call_DeleteVPCAssociationAuthorization_611763;
          body: JsonNode; Id: string): Recallable =
  ## deleteVPCAssociationAuthorization
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : When removing authorization to associate a VPC that was created by one AWS account with a hosted zone that was created with a different AWS account, the ID of the hosted zone.
  var path_611777 = newJObject()
  var body_611778 = newJObject()
  if body != nil:
    body_611778 = body
  add(path_611777, "Id", newJString(Id))
  result = call_611776.call(path_611777, nil, nil, nil, body_611778)

var deleteVPCAssociationAuthorization* = Call_DeleteVPCAssociationAuthorization_611763(
    name: "deleteVPCAssociationAuthorization", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/deauthorizevpcassociation",
    validator: validate_DeleteVPCAssociationAuthorization_611764, base: "/",
    url: url_DeleteVPCAssociationAuthorization_611765,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateVPCFromHostedZone_611779 = ref object of OpenApiRestCall_610658
proc url_DisassociateVPCFromHostedZone_611781(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/disassociatevpc")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateVPCFromHostedZone_611780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the private hosted zone that you want to disassociate a VPC from.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611782 = path.getOrDefault("Id")
  valid_611782 = validateParameter(valid_611782, JString, required = true,
                                 default = nil)
  if valid_611782 != nil:
    section.add "Id", valid_611782
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611783 = header.getOrDefault("X-Amz-Signature")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-Signature", valid_611783
  var valid_611784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "X-Amz-Content-Sha256", valid_611784
  var valid_611785 = header.getOrDefault("X-Amz-Date")
  valid_611785 = validateParameter(valid_611785, JString, required = false,
                                 default = nil)
  if valid_611785 != nil:
    section.add "X-Amz-Date", valid_611785
  var valid_611786 = header.getOrDefault("X-Amz-Credential")
  valid_611786 = validateParameter(valid_611786, JString, required = false,
                                 default = nil)
  if valid_611786 != nil:
    section.add "X-Amz-Credential", valid_611786
  var valid_611787 = header.getOrDefault("X-Amz-Security-Token")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "X-Amz-Security-Token", valid_611787
  var valid_611788 = header.getOrDefault("X-Amz-Algorithm")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "X-Amz-Algorithm", valid_611788
  var valid_611789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-SignedHeaders", valid_611789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611791: Call_DisassociateVPCFromHostedZone_611779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ## 
  let valid = call_611791.validator(path, query, header, formData, body)
  let scheme = call_611791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611791.url(scheme.get, call_611791.host, call_611791.base,
                         call_611791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611791, url, valid)

proc call*(call_611792: Call_DisassociateVPCFromHostedZone_611779; body: JsonNode;
          Id: string): Recallable =
  ## disassociateVPCFromHostedZone
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the private hosted zone that you want to disassociate a VPC from.
  var path_611793 = newJObject()
  var body_611794 = newJObject()
  if body != nil:
    body_611794 = body
  add(path_611793, "Id", newJString(Id))
  result = call_611792.call(path_611793, nil, nil, nil, body_611794)

var disassociateVPCFromHostedZone* = Call_DisassociateVPCFromHostedZone_611779(
    name: "disassociateVPCFromHostedZone", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/disassociatevpc",
    validator: validate_DisassociateVPCFromHostedZone_611780, base: "/",
    url: url_DisassociateVPCFromHostedZone_611781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountLimit_611795 = ref object of OpenApiRestCall_610658
proc url_GetAccountLimit_611797(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Type" in path, "`Type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/accountlimit/"),
               (kind: VariableSegment, value: "Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccountLimit_611796(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Type: JString (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_HEALTH_CHECKS_BY_OWNER</b>: The maximum number of health checks that you can create using the current account.</p> </li> <li> <p> <b>MAX_HOSTED_ZONES_BY_OWNER</b>: The maximum number of hosted zones that you can create using the current account.</p> </li> <li> <p> <b>MAX_REUSABLE_DELEGATION_SETS_BY_OWNER</b>: The maximum number of reusable delegation sets that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICIES_BY_OWNER</b>: The maximum number of traffic policies that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICY_INSTANCES_BY_OWNER</b>: The maximum number of traffic policy instances that you can create using the current account. (Traffic policy instances are referred to as traffic flow policy records in the Amazon Route 53 console.)</p> </li> </ul>
  section = newJObject()
  var valid_611798 = path.getOrDefault("Type")
  valid_611798 = validateParameter(valid_611798, JString, required = true, default = newJString(
      "MAX_HEALTH_CHECKS_BY_OWNER"))
  if valid_611798 != nil:
    section.add "Type", valid_611798
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611799 = header.getOrDefault("X-Amz-Signature")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-Signature", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-Content-Sha256", valid_611800
  var valid_611801 = header.getOrDefault("X-Amz-Date")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-Date", valid_611801
  var valid_611802 = header.getOrDefault("X-Amz-Credential")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-Credential", valid_611802
  var valid_611803 = header.getOrDefault("X-Amz-Security-Token")
  valid_611803 = validateParameter(valid_611803, JString, required = false,
                                 default = nil)
  if valid_611803 != nil:
    section.add "X-Amz-Security-Token", valid_611803
  var valid_611804 = header.getOrDefault("X-Amz-Algorithm")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-Algorithm", valid_611804
  var valid_611805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "X-Amz-SignedHeaders", valid_611805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611806: Call_GetAccountLimit_611795; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ## 
  let valid = call_611806.validator(path, query, header, formData, body)
  let scheme = call_611806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611806.url(scheme.get, call_611806.host, call_611806.base,
                         call_611806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611806, url, valid)

proc call*(call_611807: Call_GetAccountLimit_611795;
          Type: string = "MAX_HEALTH_CHECKS_BY_OWNER"): Recallable =
  ## getAccountLimit
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ##   Type: string (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_HEALTH_CHECKS_BY_OWNER</b>: The maximum number of health checks that you can create using the current account.</p> </li> <li> <p> <b>MAX_HOSTED_ZONES_BY_OWNER</b>: The maximum number of hosted zones that you can create using the current account.</p> </li> <li> <p> <b>MAX_REUSABLE_DELEGATION_SETS_BY_OWNER</b>: The maximum number of reusable delegation sets that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICIES_BY_OWNER</b>: The maximum number of traffic policies that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICY_INSTANCES_BY_OWNER</b>: The maximum number of traffic policy instances that you can create using the current account. (Traffic policy instances are referred to as traffic flow policy records in the Amazon Route 53 console.)</p> </li> </ul>
  var path_611808 = newJObject()
  add(path_611808, "Type", newJString(Type))
  result = call_611807.call(path_611808, nil, nil, nil, nil)

var getAccountLimit* = Call_GetAccountLimit_611795(name: "getAccountLimit",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/accountlimit/{Type}", validator: validate_GetAccountLimit_611796,
    base: "/", url: url_GetAccountLimit_611797, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChange_611809 = ref object of OpenApiRestCall_610658
proc url_GetChange_611811(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/change/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetChange_611810(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the change batch request. The value that you specify here is the value that <code>ChangeResourceRecordSets</code> returned in the <code>Id</code> element when you submitted the request.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611812 = path.getOrDefault("Id")
  valid_611812 = validateParameter(valid_611812, JString, required = true,
                                 default = nil)
  if valid_611812 != nil:
    section.add "Id", valid_611812
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611813 = header.getOrDefault("X-Amz-Signature")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Signature", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Content-Sha256", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-Date")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-Date", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-Credential")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Credential", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-Security-Token")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-Security-Token", valid_611817
  var valid_611818 = header.getOrDefault("X-Amz-Algorithm")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-Algorithm", valid_611818
  var valid_611819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "X-Amz-SignedHeaders", valid_611819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611820: Call_GetChange_611809; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ## 
  let valid = call_611820.validator(path, query, header, formData, body)
  let scheme = call_611820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611820.url(scheme.get, call_611820.host, call_611820.base,
                         call_611820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611820, url, valid)

proc call*(call_611821: Call_GetChange_611809; Id: string): Recallable =
  ## getChange
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the change batch request. The value that you specify here is the value that <code>ChangeResourceRecordSets</code> returned in the <code>Id</code> element when you submitted the request.
  var path_611822 = newJObject()
  add(path_611822, "Id", newJString(Id))
  result = call_611821.call(path_611822, nil, nil, nil, nil)

var getChange* = Call_GetChange_611809(name: "getChange", meth: HttpMethod.HttpGet,
                                    host: "route53.amazonaws.com",
                                    route: "/2013-04-01/change/{Id}",
                                    validator: validate_GetChange_611810,
                                    base: "/", url: url_GetChange_611811,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckerIpRanges_611823 = ref object of OpenApiRestCall_610658
proc url_GetCheckerIpRanges_611825(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCheckerIpRanges_611824(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611826 = header.getOrDefault("X-Amz-Signature")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Signature", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-Content-Sha256", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-Date")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Date", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-Credential")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Credential", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-Security-Token")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-Security-Token", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-Algorithm")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Algorithm", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-SignedHeaders", valid_611832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611833: Call_GetCheckerIpRanges_611823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  let valid = call_611833.validator(path, query, header, formData, body)
  let scheme = call_611833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611833.url(scheme.get, call_611833.host, call_611833.base,
                         call_611833.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611833, url, valid)

proc call*(call_611834: Call_GetCheckerIpRanges_611823): Recallable =
  ## getCheckerIpRanges
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  result = call_611834.call(nil, nil, nil, nil, nil)

var getCheckerIpRanges* = Call_GetCheckerIpRanges_611823(
    name: "getCheckerIpRanges", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/checkeripranges",
    validator: validate_GetCheckerIpRanges_611824, base: "/",
    url: url_GetCheckerIpRanges_611825, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGeoLocation_611835 = ref object of OpenApiRestCall_610658
proc url_GetGeoLocation_611837(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGeoLocation_611836(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   continentcode: JString
  ##                : <p>Amazon Route 53 supports the following continent codes:</p> <ul> <li> <p> <b>AF</b>: Africa</p> </li> <li> <p> <b>AN</b>: Antarctica</p> </li> <li> <p> <b>AS</b>: Asia</p> </li> <li> <p> <b>EU</b>: Europe</p> </li> <li> <p> <b>OC</b>: Oceania</p> </li> <li> <p> <b>NA</b>: North America</p> </li> <li> <p> <b>SA</b>: South America</p> </li> </ul>
  ##   countrycode: JString
  ##              : Amazon Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.
  ##   subdivisioncode: JString
  ##                  : Amazon Route 53 uses the one- to three-letter subdivision codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>. Route 53 doesn't support subdivision codes for all countries. If you specify <code>subdivisioncode</code>, you must also specify <code>countrycode</code>. 
  section = newJObject()
  var valid_611838 = query.getOrDefault("continentcode")
  valid_611838 = validateParameter(valid_611838, JString, required = false,
                                 default = nil)
  if valid_611838 != nil:
    section.add "continentcode", valid_611838
  var valid_611839 = query.getOrDefault("countrycode")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "countrycode", valid_611839
  var valid_611840 = query.getOrDefault("subdivisioncode")
  valid_611840 = validateParameter(valid_611840, JString, required = false,
                                 default = nil)
  if valid_611840 != nil:
    section.add "subdivisioncode", valid_611840
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611841 = header.getOrDefault("X-Amz-Signature")
  valid_611841 = validateParameter(valid_611841, JString, required = false,
                                 default = nil)
  if valid_611841 != nil:
    section.add "X-Amz-Signature", valid_611841
  var valid_611842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611842 = validateParameter(valid_611842, JString, required = false,
                                 default = nil)
  if valid_611842 != nil:
    section.add "X-Amz-Content-Sha256", valid_611842
  var valid_611843 = header.getOrDefault("X-Amz-Date")
  valid_611843 = validateParameter(valid_611843, JString, required = false,
                                 default = nil)
  if valid_611843 != nil:
    section.add "X-Amz-Date", valid_611843
  var valid_611844 = header.getOrDefault("X-Amz-Credential")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Credential", valid_611844
  var valid_611845 = header.getOrDefault("X-Amz-Security-Token")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-Security-Token", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-Algorithm")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-Algorithm", valid_611846
  var valid_611847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-SignedHeaders", valid_611847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611848: Call_GetGeoLocation_611835; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ## 
  let valid = call_611848.validator(path, query, header, formData, body)
  let scheme = call_611848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611848.url(scheme.get, call_611848.host, call_611848.base,
                         call_611848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611848, url, valid)

proc call*(call_611849: Call_GetGeoLocation_611835; continentcode: string = "";
          countrycode: string = ""; subdivisioncode: string = ""): Recallable =
  ## getGeoLocation
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ##   continentcode: string
  ##                : <p>Amazon Route 53 supports the following continent codes:</p> <ul> <li> <p> <b>AF</b>: Africa</p> </li> <li> <p> <b>AN</b>: Antarctica</p> </li> <li> <p> <b>AS</b>: Asia</p> </li> <li> <p> <b>EU</b>: Europe</p> </li> <li> <p> <b>OC</b>: Oceania</p> </li> <li> <p> <b>NA</b>: North America</p> </li> <li> <p> <b>SA</b>: South America</p> </li> </ul>
  ##   countrycode: string
  ##              : Amazon Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.
  ##   subdivisioncode: string
  ##                  : Amazon Route 53 uses the one- to three-letter subdivision codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>. Route 53 doesn't support subdivision codes for all countries. If you specify <code>subdivisioncode</code>, you must also specify <code>countrycode</code>. 
  var query_611850 = newJObject()
  add(query_611850, "continentcode", newJString(continentcode))
  add(query_611850, "countrycode", newJString(countrycode))
  add(query_611850, "subdivisioncode", newJString(subdivisioncode))
  result = call_611849.call(nil, query_611850, nil, nil, nil)

var getGeoLocation* = Call_GetGeoLocation_611835(name: "getGeoLocation",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/geolocation", validator: validate_GetGeoLocation_611836,
    base: "/", url: url_GetGeoLocation_611837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckCount_611851 = ref object of OpenApiRestCall_610658
proc url_GetHealthCheckCount_611853(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetHealthCheckCount_611852(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the number of health checks that are associated with the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611854 = header.getOrDefault("X-Amz-Signature")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "X-Amz-Signature", valid_611854
  var valid_611855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "X-Amz-Content-Sha256", valid_611855
  var valid_611856 = header.getOrDefault("X-Amz-Date")
  valid_611856 = validateParameter(valid_611856, JString, required = false,
                                 default = nil)
  if valid_611856 != nil:
    section.add "X-Amz-Date", valid_611856
  var valid_611857 = header.getOrDefault("X-Amz-Credential")
  valid_611857 = validateParameter(valid_611857, JString, required = false,
                                 default = nil)
  if valid_611857 != nil:
    section.add "X-Amz-Credential", valid_611857
  var valid_611858 = header.getOrDefault("X-Amz-Security-Token")
  valid_611858 = validateParameter(valid_611858, JString, required = false,
                                 default = nil)
  if valid_611858 != nil:
    section.add "X-Amz-Security-Token", valid_611858
  var valid_611859 = header.getOrDefault("X-Amz-Algorithm")
  valid_611859 = validateParameter(valid_611859, JString, required = false,
                                 default = nil)
  if valid_611859 != nil:
    section.add "X-Amz-Algorithm", valid_611859
  var valid_611860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "X-Amz-SignedHeaders", valid_611860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611861: Call_GetHealthCheckCount_611851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the number of health checks that are associated with the current AWS account.
  ## 
  let valid = call_611861.validator(path, query, header, formData, body)
  let scheme = call_611861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611861.url(scheme.get, call_611861.host, call_611861.base,
                         call_611861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611861, url, valid)

proc call*(call_611862: Call_GetHealthCheckCount_611851): Recallable =
  ## getHealthCheckCount
  ## Retrieves the number of health checks that are associated with the current AWS account.
  result = call_611862.call(nil, nil, nil, nil, nil)

var getHealthCheckCount* = Call_GetHealthCheckCount_611851(
    name: "getHealthCheckCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/healthcheckcount",
    validator: validate_GetHealthCheckCount_611852, base: "/",
    url: url_GetHealthCheckCount_611853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckLastFailureReason_611863 = ref object of OpenApiRestCall_610658
proc url_GetHealthCheckLastFailureReason_611865(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId"),
               (kind: ConstantSegment, value: "/lastfailurereason")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHealthCheckLastFailureReason_611864(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the reason that a specified health check failed most recently.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : <p>The ID for the health check for which you want the last failure reason. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to get the last failure reason for a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckLastFailureReason</code> for a calculated health check.</p> </note>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_611866 = path.getOrDefault("HealthCheckId")
  valid_611866 = validateParameter(valid_611866, JString, required = true,
                                 default = nil)
  if valid_611866 != nil:
    section.add "HealthCheckId", valid_611866
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611867 = header.getOrDefault("X-Amz-Signature")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-Signature", valid_611867
  var valid_611868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-Content-Sha256", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-Date")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-Date", valid_611869
  var valid_611870 = header.getOrDefault("X-Amz-Credential")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "X-Amz-Credential", valid_611870
  var valid_611871 = header.getOrDefault("X-Amz-Security-Token")
  valid_611871 = validateParameter(valid_611871, JString, required = false,
                                 default = nil)
  if valid_611871 != nil:
    section.add "X-Amz-Security-Token", valid_611871
  var valid_611872 = header.getOrDefault("X-Amz-Algorithm")
  valid_611872 = validateParameter(valid_611872, JString, required = false,
                                 default = nil)
  if valid_611872 != nil:
    section.add "X-Amz-Algorithm", valid_611872
  var valid_611873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611873 = validateParameter(valid_611873, JString, required = false,
                                 default = nil)
  if valid_611873 != nil:
    section.add "X-Amz-SignedHeaders", valid_611873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611874: Call_GetHealthCheckLastFailureReason_611863;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the reason that a specified health check failed most recently.
  ## 
  let valid = call_611874.validator(path, query, header, formData, body)
  let scheme = call_611874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611874.url(scheme.get, call_611874.host, call_611874.base,
                         call_611874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611874, url, valid)

proc call*(call_611875: Call_GetHealthCheckLastFailureReason_611863;
          HealthCheckId: string): Recallable =
  ## getHealthCheckLastFailureReason
  ## Gets the reason that a specified health check failed most recently.
  ##   HealthCheckId: string (required)
  ##                : <p>The ID for the health check for which you want the last failure reason. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to get the last failure reason for a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckLastFailureReason</code> for a calculated health check.</p> </note>
  var path_611876 = newJObject()
  add(path_611876, "HealthCheckId", newJString(HealthCheckId))
  result = call_611875.call(path_611876, nil, nil, nil, nil)

var getHealthCheckLastFailureReason* = Call_GetHealthCheckLastFailureReason_611863(
    name: "getHealthCheckLastFailureReason", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}/lastfailurereason",
    validator: validate_GetHealthCheckLastFailureReason_611864, base: "/",
    url: url_GetHealthCheckLastFailureReason_611865,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckStatus_611877 = ref object of OpenApiRestCall_610658
proc url_GetHealthCheckStatus_611879(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId"),
               (kind: ConstantSegment, value: "/status")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHealthCheckStatus_611878(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets status of a specified health check. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : <p>The ID for the health check that you want the current status for. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to check the status of a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckStatus</code> to get the status of a calculated health check.</p> </note>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_611880 = path.getOrDefault("HealthCheckId")
  valid_611880 = validateParameter(valid_611880, JString, required = true,
                                 default = nil)
  if valid_611880 != nil:
    section.add "HealthCheckId", valid_611880
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611881 = header.getOrDefault("X-Amz-Signature")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Signature", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Content-Sha256", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-Date")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-Date", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-Credential")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Credential", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-Security-Token")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-Security-Token", valid_611885
  var valid_611886 = header.getOrDefault("X-Amz-Algorithm")
  valid_611886 = validateParameter(valid_611886, JString, required = false,
                                 default = nil)
  if valid_611886 != nil:
    section.add "X-Amz-Algorithm", valid_611886
  var valid_611887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611887 = validateParameter(valid_611887, JString, required = false,
                                 default = nil)
  if valid_611887 != nil:
    section.add "X-Amz-SignedHeaders", valid_611887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611888: Call_GetHealthCheckStatus_611877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets status of a specified health check. 
  ## 
  let valid = call_611888.validator(path, query, header, formData, body)
  let scheme = call_611888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611888.url(scheme.get, call_611888.host, call_611888.base,
                         call_611888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611888, url, valid)

proc call*(call_611889: Call_GetHealthCheckStatus_611877; HealthCheckId: string): Recallable =
  ## getHealthCheckStatus
  ## Gets status of a specified health check. 
  ##   HealthCheckId: string (required)
  ##                : <p>The ID for the health check that you want the current status for. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to check the status of a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckStatus</code> to get the status of a calculated health check.</p> </note>
  var path_611890 = newJObject()
  add(path_611890, "HealthCheckId", newJString(HealthCheckId))
  result = call_611889.call(path_611890, nil, nil, nil, nil)

var getHealthCheckStatus* = Call_GetHealthCheckStatus_611877(
    name: "getHealthCheckStatus", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}/status",
    validator: validate_GetHealthCheckStatus_611878, base: "/",
    url: url_GetHealthCheckStatus_611879, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZoneCount_611891 = ref object of OpenApiRestCall_610658
proc url_GetHostedZoneCount_611893(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetHostedZoneCount_611892(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611894 = header.getOrDefault("X-Amz-Signature")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Signature", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Content-Sha256", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Date")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Date", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-Credential")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Credential", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-Security-Token")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-Security-Token", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-Algorithm")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Algorithm", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-SignedHeaders", valid_611900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611901: Call_GetHostedZoneCount_611891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
  ## 
  let valid = call_611901.validator(path, query, header, formData, body)
  let scheme = call_611901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611901.url(scheme.get, call_611901.host, call_611901.base,
                         call_611901.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611901, url, valid)

proc call*(call_611902: Call_GetHostedZoneCount_611891): Recallable =
  ## getHostedZoneCount
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
  result = call_611902.call(nil, nil, nil, nil, nil)

var getHostedZoneCount* = Call_GetHostedZoneCount_611891(
    name: "getHostedZoneCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzonecount",
    validator: validate_GetHostedZoneCount_611892, base: "/",
    url: url_GetHostedZoneCount_611893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZoneLimit_611903 = ref object of OpenApiRestCall_610658
proc url_GetHostedZoneLimit_611905(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Type" in path, "`Type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzonelimit/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHostedZoneLimit_611904(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Type: JString (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_RRSETS_BY_ZONE</b>: The maximum number of records that you can create in the specified hosted zone.</p> </li> <li> <p> <b>MAX_VPCS_ASSOCIATED_BY_ZONE</b>: The maximum number of Amazon VPCs that you can associate with the specified private hosted zone.</p> </li> </ul>
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that you want to get a limit for.
  section = newJObject()
  var valid_611906 = path.getOrDefault("Type")
  valid_611906 = validateParameter(valid_611906, JString, required = true,
                                 default = newJString("MAX_RRSETS_BY_ZONE"))
  if valid_611906 != nil:
    section.add "Type", valid_611906
  var valid_611907 = path.getOrDefault("Id")
  valid_611907 = validateParameter(valid_611907, JString, required = true,
                                 default = nil)
  if valid_611907 != nil:
    section.add "Id", valid_611907
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611908 = header.getOrDefault("X-Amz-Signature")
  valid_611908 = validateParameter(valid_611908, JString, required = false,
                                 default = nil)
  if valid_611908 != nil:
    section.add "X-Amz-Signature", valid_611908
  var valid_611909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611909 = validateParameter(valid_611909, JString, required = false,
                                 default = nil)
  if valid_611909 != nil:
    section.add "X-Amz-Content-Sha256", valid_611909
  var valid_611910 = header.getOrDefault("X-Amz-Date")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-Date", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Credential")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Credential", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-Security-Token")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-Security-Token", valid_611912
  var valid_611913 = header.getOrDefault("X-Amz-Algorithm")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "X-Amz-Algorithm", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-SignedHeaders", valid_611914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611915: Call_GetHostedZoneLimit_611903; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  let valid = call_611915.validator(path, query, header, formData, body)
  let scheme = call_611915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611915.url(scheme.get, call_611915.host, call_611915.base,
                         call_611915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611915, url, valid)

proc call*(call_611916: Call_GetHostedZoneLimit_611903; Id: string;
          Type: string = "MAX_RRSETS_BY_ZONE"): Recallable =
  ## getHostedZoneLimit
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ##   Type: string (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_RRSETS_BY_ZONE</b>: The maximum number of records that you can create in the specified hosted zone.</p> </li> <li> <p> <b>MAX_VPCS_ASSOCIATED_BY_ZONE</b>: The maximum number of Amazon VPCs that you can associate with the specified private hosted zone.</p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the hosted zone that you want to get a limit for.
  var path_611917 = newJObject()
  add(path_611917, "Type", newJString(Type))
  add(path_611917, "Id", newJString(Id))
  result = call_611916.call(path_611917, nil, nil, nil, nil)

var getHostedZoneLimit* = Call_GetHostedZoneLimit_611903(
    name: "getHostedZoneLimit", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzonelimit/{Id}/{Type}",
    validator: validate_GetHostedZoneLimit_611904, base: "/",
    url: url_GetHostedZoneLimit_611905, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReusableDelegationSetLimit_611918 = ref object of OpenApiRestCall_610658
proc url_GetReusableDelegationSetLimit_611920(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Type" in path, "`Type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2013-04-01/reusabledelegationsetlimit/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetReusableDelegationSetLimit_611919(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Type: JString (required)
  ##       : Specify <code>MAX_ZONES_BY_REUSABLE_DELEGATION_SET</code> to get the maximum number of hosted zones that you can associate with the specified reusable delegation set.
  ##   Id: JString (required)
  ##     : The ID of the delegation set that you want to get the limit for.
  section = newJObject()
  var valid_611921 = path.getOrDefault("Type")
  valid_611921 = validateParameter(valid_611921, JString, required = true, default = newJString(
      "MAX_ZONES_BY_REUSABLE_DELEGATION_SET"))
  if valid_611921 != nil:
    section.add "Type", valid_611921
  var valid_611922 = path.getOrDefault("Id")
  valid_611922 = validateParameter(valid_611922, JString, required = true,
                                 default = nil)
  if valid_611922 != nil:
    section.add "Id", valid_611922
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611923 = header.getOrDefault("X-Amz-Signature")
  valid_611923 = validateParameter(valid_611923, JString, required = false,
                                 default = nil)
  if valid_611923 != nil:
    section.add "X-Amz-Signature", valid_611923
  var valid_611924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611924 = validateParameter(valid_611924, JString, required = false,
                                 default = nil)
  if valid_611924 != nil:
    section.add "X-Amz-Content-Sha256", valid_611924
  var valid_611925 = header.getOrDefault("X-Amz-Date")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "X-Amz-Date", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Credential")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Credential", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-Security-Token")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-Security-Token", valid_611927
  var valid_611928 = header.getOrDefault("X-Amz-Algorithm")
  valid_611928 = validateParameter(valid_611928, JString, required = false,
                                 default = nil)
  if valid_611928 != nil:
    section.add "X-Amz-Algorithm", valid_611928
  var valid_611929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-SignedHeaders", valid_611929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611930: Call_GetReusableDelegationSetLimit_611918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  let valid = call_611930.validator(path, query, header, formData, body)
  let scheme = call_611930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611930.url(scheme.get, call_611930.host, call_611930.base,
                         call_611930.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611930, url, valid)

proc call*(call_611931: Call_GetReusableDelegationSetLimit_611918; Id: string;
          Type: string = "MAX_ZONES_BY_REUSABLE_DELEGATION_SET"): Recallable =
  ## getReusableDelegationSetLimit
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ##   Type: string (required)
  ##       : Specify <code>MAX_ZONES_BY_REUSABLE_DELEGATION_SET</code> to get the maximum number of hosted zones that you can associate with the specified reusable delegation set.
  ##   Id: string (required)
  ##     : The ID of the delegation set that you want to get the limit for.
  var path_611932 = newJObject()
  add(path_611932, "Type", newJString(Type))
  add(path_611932, "Id", newJString(Id))
  result = call_611931.call(path_611932, nil, nil, nil, nil)

var getReusableDelegationSetLimit* = Call_GetReusableDelegationSetLimit_611918(
    name: "getReusableDelegationSetLimit", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/reusabledelegationsetlimit/{Id}/{Type}",
    validator: validate_GetReusableDelegationSetLimit_611919, base: "/",
    url: url_GetReusableDelegationSetLimit_611920,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicyInstanceCount_611933 = ref object of OpenApiRestCall_610658
proc url_GetTrafficPolicyInstanceCount_611935(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTrafficPolicyInstanceCount_611934(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611936 = header.getOrDefault("X-Amz-Signature")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-Signature", valid_611936
  var valid_611937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611937 = validateParameter(valid_611937, JString, required = false,
                                 default = nil)
  if valid_611937 != nil:
    section.add "X-Amz-Content-Sha256", valid_611937
  var valid_611938 = header.getOrDefault("X-Amz-Date")
  valid_611938 = validateParameter(valid_611938, JString, required = false,
                                 default = nil)
  if valid_611938 != nil:
    section.add "X-Amz-Date", valid_611938
  var valid_611939 = header.getOrDefault("X-Amz-Credential")
  valid_611939 = validateParameter(valid_611939, JString, required = false,
                                 default = nil)
  if valid_611939 != nil:
    section.add "X-Amz-Credential", valid_611939
  var valid_611940 = header.getOrDefault("X-Amz-Security-Token")
  valid_611940 = validateParameter(valid_611940, JString, required = false,
                                 default = nil)
  if valid_611940 != nil:
    section.add "X-Amz-Security-Token", valid_611940
  var valid_611941 = header.getOrDefault("X-Amz-Algorithm")
  valid_611941 = validateParameter(valid_611941, JString, required = false,
                                 default = nil)
  if valid_611941 != nil:
    section.add "X-Amz-Algorithm", valid_611941
  var valid_611942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611942 = validateParameter(valid_611942, JString, required = false,
                                 default = nil)
  if valid_611942 != nil:
    section.add "X-Amz-SignedHeaders", valid_611942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611943: Call_GetTrafficPolicyInstanceCount_611933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
  ## 
  let valid = call_611943.validator(path, query, header, formData, body)
  let scheme = call_611943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611943.url(scheme.get, call_611943.host, call_611943.base,
                         call_611943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611943, url, valid)

proc call*(call_611944: Call_GetTrafficPolicyInstanceCount_611933): Recallable =
  ## getTrafficPolicyInstanceCount
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
  result = call_611944.call(nil, nil, nil, nil, nil)

var getTrafficPolicyInstanceCount* = Call_GetTrafficPolicyInstanceCount_611933(
    name: "getTrafficPolicyInstanceCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstancecount",
    validator: validate_GetTrafficPolicyInstanceCount_611934, base: "/",
    url: url_GetTrafficPolicyInstanceCount_611935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGeoLocations_611945 = ref object of OpenApiRestCall_610658
proc url_ListGeoLocations_611947(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGeoLocations_611946(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   startcountrycode: JString
  ##                   : <p>The code for the country with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextCountryCode</code> from the previous response has a value, enter that value in <code>startcountrycode</code> to return the next page of results.</p> <p>Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.</p>
  ##   startsubdivisioncode: JString
  ##                       : <p>The code for the subdivision (for example, state or province) with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextSubdivisionCode</code> from the previous response has a value, enter that value in <code>startsubdivisioncode</code> to return the next page of results.</p> <p>To list subdivisions of a country, you must include both <code>startcountrycode</code> and <code>startsubdivisioncode</code>.</p>
  ##   startcontinentcode: JString
  ##                     : <p>The code for the continent with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is true, and if <code>NextContinentCode</code> from the previous response has a value, enter that value in <code>startcontinentcode</code> to return the next page of results.</p> <p>Include <code>startcontinentcode</code> only if you want to list continents. Don't include <code>startcontinentcode</code> when you're listing countries or countries with their subdivisions.</p>
  ##   maxitems: JString
  ##           : (Optional) The maximum number of geolocations to be included in the response body for this request. If more than <code>maxitems</code> geolocations remain to be listed, then the value of the <code>IsTruncated</code> element in the response is <code>true</code>.
  section = newJObject()
  var valid_611948 = query.getOrDefault("startcountrycode")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "startcountrycode", valid_611948
  var valid_611949 = query.getOrDefault("startsubdivisioncode")
  valid_611949 = validateParameter(valid_611949, JString, required = false,
                                 default = nil)
  if valid_611949 != nil:
    section.add "startsubdivisioncode", valid_611949
  var valid_611950 = query.getOrDefault("startcontinentcode")
  valid_611950 = validateParameter(valid_611950, JString, required = false,
                                 default = nil)
  if valid_611950 != nil:
    section.add "startcontinentcode", valid_611950
  var valid_611951 = query.getOrDefault("maxitems")
  valid_611951 = validateParameter(valid_611951, JString, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "maxitems", valid_611951
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611952 = header.getOrDefault("X-Amz-Signature")
  valid_611952 = validateParameter(valid_611952, JString, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "X-Amz-Signature", valid_611952
  var valid_611953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611953 = validateParameter(valid_611953, JString, required = false,
                                 default = nil)
  if valid_611953 != nil:
    section.add "X-Amz-Content-Sha256", valid_611953
  var valid_611954 = header.getOrDefault("X-Amz-Date")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Date", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-Credential")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-Credential", valid_611955
  var valid_611956 = header.getOrDefault("X-Amz-Security-Token")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-Security-Token", valid_611956
  var valid_611957 = header.getOrDefault("X-Amz-Algorithm")
  valid_611957 = validateParameter(valid_611957, JString, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "X-Amz-Algorithm", valid_611957
  var valid_611958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611958 = validateParameter(valid_611958, JString, required = false,
                                 default = nil)
  if valid_611958 != nil:
    section.add "X-Amz-SignedHeaders", valid_611958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611959: Call_ListGeoLocations_611945; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ## 
  let valid = call_611959.validator(path, query, header, formData, body)
  let scheme = call_611959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611959.url(scheme.get, call_611959.host, call_611959.base,
                         call_611959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611959, url, valid)

proc call*(call_611960: Call_ListGeoLocations_611945;
          startcountrycode: string = ""; startsubdivisioncode: string = "";
          startcontinentcode: string = ""; maxitems: string = ""): Recallable =
  ## listGeoLocations
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ##   startcountrycode: string
  ##                   : <p>The code for the country with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextCountryCode</code> from the previous response has a value, enter that value in <code>startcountrycode</code> to return the next page of results.</p> <p>Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.</p>
  ##   startsubdivisioncode: string
  ##                       : <p>The code for the subdivision (for example, state or province) with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextSubdivisionCode</code> from the previous response has a value, enter that value in <code>startsubdivisioncode</code> to return the next page of results.</p> <p>To list subdivisions of a country, you must include both <code>startcountrycode</code> and <code>startsubdivisioncode</code>.</p>
  ##   startcontinentcode: string
  ##                     : <p>The code for the continent with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is true, and if <code>NextContinentCode</code> from the previous response has a value, enter that value in <code>startcontinentcode</code> to return the next page of results.</p> <p>Include <code>startcontinentcode</code> only if you want to list continents. Don't include <code>startcontinentcode</code> when you're listing countries or countries with their subdivisions.</p>
  ##   maxitems: string
  ##           : (Optional) The maximum number of geolocations to be included in the response body for this request. If more than <code>maxitems</code> geolocations remain to be listed, then the value of the <code>IsTruncated</code> element in the response is <code>true</code>.
  var query_611961 = newJObject()
  add(query_611961, "startcountrycode", newJString(startcountrycode))
  add(query_611961, "startsubdivisioncode", newJString(startsubdivisioncode))
  add(query_611961, "startcontinentcode", newJString(startcontinentcode))
  add(query_611961, "maxitems", newJString(maxitems))
  result = call_611960.call(nil, query_611961, nil, nil, nil)

var listGeoLocations* = Call_ListGeoLocations_611945(name: "listGeoLocations",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/geolocations", validator: validate_ListGeoLocations_611946,
    base: "/", url: url_ListGeoLocations_611947,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHostedZonesByName_611962 = ref object of OpenApiRestCall_610658
proc url_ListHostedZonesByName_611964(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHostedZonesByName_611963(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   dnsname: JString
  ##          : (Optional) For your first request to <code>ListHostedZonesByName</code>, include the <code>dnsname</code> parameter only if you want to specify the name of the first hosted zone in the response. If you don't include the <code>dnsname</code> parameter, Amazon Route 53 returns all of the hosted zones that were created by the current AWS account, in ASCII order. For subsequent requests, include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For <code>dnsname</code>, specify the value of <code>NextDNSName</code> from the previous response.
  ##   maxitems: JString
  ##           : The maximum number of hosted zones to be included in the response body for this request. If you have more than <code>maxitems</code> hosted zones, then the value of the <code>IsTruncated</code> element in the response is true, and the values of <code>NextDNSName</code> and <code>NextHostedZoneId</code> specify the first hosted zone in the next group of <code>maxitems</code> hosted zones. 
  ##   hostedzoneid: JString
  ##               : <p>(Optional) For your first request to <code>ListHostedZonesByName</code>, do not include the <code>hostedzoneid</code> parameter.</p> <p>If you have more hosted zones than the value of <code>maxitems</code>, <code>ListHostedZonesByName</code> returns only the first <code>maxitems</code> hosted zones. To get the next group of <code>maxitems</code> hosted zones, submit another request to <code>ListHostedZonesByName</code> and include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For the value of <code>hostedzoneid</code>, specify the value of the <code>NextHostedZoneId</code> element from the previous response.</p>
  section = newJObject()
  var valid_611965 = query.getOrDefault("dnsname")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "dnsname", valid_611965
  var valid_611966 = query.getOrDefault("maxitems")
  valid_611966 = validateParameter(valid_611966, JString, required = false,
                                 default = nil)
  if valid_611966 != nil:
    section.add "maxitems", valid_611966
  var valid_611967 = query.getOrDefault("hostedzoneid")
  valid_611967 = validateParameter(valid_611967, JString, required = false,
                                 default = nil)
  if valid_611967 != nil:
    section.add "hostedzoneid", valid_611967
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611968 = header.getOrDefault("X-Amz-Signature")
  valid_611968 = validateParameter(valid_611968, JString, required = false,
                                 default = nil)
  if valid_611968 != nil:
    section.add "X-Amz-Signature", valid_611968
  var valid_611969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611969 = validateParameter(valid_611969, JString, required = false,
                                 default = nil)
  if valid_611969 != nil:
    section.add "X-Amz-Content-Sha256", valid_611969
  var valid_611970 = header.getOrDefault("X-Amz-Date")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "X-Amz-Date", valid_611970
  var valid_611971 = header.getOrDefault("X-Amz-Credential")
  valid_611971 = validateParameter(valid_611971, JString, required = false,
                                 default = nil)
  if valid_611971 != nil:
    section.add "X-Amz-Credential", valid_611971
  var valid_611972 = header.getOrDefault("X-Amz-Security-Token")
  valid_611972 = validateParameter(valid_611972, JString, required = false,
                                 default = nil)
  if valid_611972 != nil:
    section.add "X-Amz-Security-Token", valid_611972
  var valid_611973 = header.getOrDefault("X-Amz-Algorithm")
  valid_611973 = validateParameter(valid_611973, JString, required = false,
                                 default = nil)
  if valid_611973 != nil:
    section.add "X-Amz-Algorithm", valid_611973
  var valid_611974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "X-Amz-SignedHeaders", valid_611974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611975: Call_ListHostedZonesByName_611962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ## 
  let valid = call_611975.validator(path, query, header, formData, body)
  let scheme = call_611975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611975.url(scheme.get, call_611975.host, call_611975.base,
                         call_611975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611975, url, valid)

proc call*(call_611976: Call_ListHostedZonesByName_611962; dnsname: string = "";
          maxitems: string = ""; hostedzoneid: string = ""): Recallable =
  ## listHostedZonesByName
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ##   dnsname: string
  ##          : (Optional) For your first request to <code>ListHostedZonesByName</code>, include the <code>dnsname</code> parameter only if you want to specify the name of the first hosted zone in the response. If you don't include the <code>dnsname</code> parameter, Amazon Route 53 returns all of the hosted zones that were created by the current AWS account, in ASCII order. For subsequent requests, include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For <code>dnsname</code>, specify the value of <code>NextDNSName</code> from the previous response.
  ##   maxitems: string
  ##           : The maximum number of hosted zones to be included in the response body for this request. If you have more than <code>maxitems</code> hosted zones, then the value of the <code>IsTruncated</code> element in the response is true, and the values of <code>NextDNSName</code> and <code>NextHostedZoneId</code> specify the first hosted zone in the next group of <code>maxitems</code> hosted zones. 
  ##   hostedzoneid: string
  ##               : <p>(Optional) For your first request to <code>ListHostedZonesByName</code>, do not include the <code>hostedzoneid</code> parameter.</p> <p>If you have more hosted zones than the value of <code>maxitems</code>, <code>ListHostedZonesByName</code> returns only the first <code>maxitems</code> hosted zones. To get the next group of <code>maxitems</code> hosted zones, submit another request to <code>ListHostedZonesByName</code> and include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For the value of <code>hostedzoneid</code>, specify the value of the <code>NextHostedZoneId</code> element from the previous response.</p>
  var query_611977 = newJObject()
  add(query_611977, "dnsname", newJString(dnsname))
  add(query_611977, "maxitems", newJString(maxitems))
  add(query_611977, "hostedzoneid", newJString(hostedzoneid))
  result = call_611976.call(nil, query_611977, nil, nil, nil)

var listHostedZonesByName* = Call_ListHostedZonesByName_611962(
    name: "listHostedZonesByName", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzonesbyname",
    validator: validate_ListHostedZonesByName_611963, base: "/",
    url: url_ListHostedZonesByName_611964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceRecordSets_611978 = ref object of OpenApiRestCall_610658
proc url_ListResourceRecordSets_611980(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/rrset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListResourceRecordSets_611979(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to list.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611981 = path.getOrDefault("Id")
  valid_611981 = validateParameter(valid_611981, JString, required = true,
                                 default = nil)
  if valid_611981 != nil:
    section.add "Id", valid_611981
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : The first name in the lexicographic ordering of resource record sets that you want to list.
  ##   MaxItems: JString
  ##           : Pagination limit
  ##   type: JString
  ##       : <p>The type of resource record set to begin the record listing from.</p> <p>Valid values for basic resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>NS</code> | <code>PTR</code> | <code>SOA</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for weighted, latency, geolocation, and failover resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>PTR</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for alias resource record sets: </p> <ul> <li> <p> <b>API Gateway custom regional API or edge-optimized API</b>: A</p> </li> <li> <p> <b>CloudFront distribution</b>: A or AAAA</p> </li> <li> <p> <b>Elastic Beanstalk environment that has a regionalized subdomain</b>: A</p> </li> <li> <p> <b>Elastic Load Balancing load balancer</b>: A | AAAA</p> </li> <li> <p> <b>Amazon S3 bucket</b>: A</p> </li> <li> <p> <b>Amazon VPC interface VPC endpoint</b>: A</p> </li> <li> <p> <b>Another resource record set in this hosted zone:</b> The type of the resource record set that the alias references.</p> </li> </ul> <p>Constraint: Specifying <code>type</code> without specifying <code>name</code> returns an <code>InvalidInput</code> error.</p>
  ##   maxitems: JString
  ##           : (Optional) The maximum number of resource records sets to include in the response body for this request. If the response includes more than <code>maxitems</code> resource record sets, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of the <code>NextRecordName</code> and <code>NextRecordType</code> elements in the response identify the first resource record set in the next group of <code>maxitems</code> resource record sets.
  ##   StartRecordName: JString
  ##                  : Pagination token
  ##   StartRecordIdentifier: JString
  ##                        : Pagination token
  ##   StartRecordType: JString
  ##                  : Pagination token
  ##   identifier: JString
  ##             :  <i>Resource record sets that have a routing policy other than simple:</i> If results were truncated for a given DNS name and type, specify the value of <code>NextRecordIdentifier</code> from the previous response to get the next resource record set that has the current DNS name and type.
  section = newJObject()
  var valid_611982 = query.getOrDefault("name")
  valid_611982 = validateParameter(valid_611982, JString, required = false,
                                 default = nil)
  if valid_611982 != nil:
    section.add "name", valid_611982
  var valid_611983 = query.getOrDefault("MaxItems")
  valid_611983 = validateParameter(valid_611983, JString, required = false,
                                 default = nil)
  if valid_611983 != nil:
    section.add "MaxItems", valid_611983
  var valid_611984 = query.getOrDefault("type")
  valid_611984 = validateParameter(valid_611984, JString, required = false,
                                 default = newJString("SOA"))
  if valid_611984 != nil:
    section.add "type", valid_611984
  var valid_611985 = query.getOrDefault("maxitems")
  valid_611985 = validateParameter(valid_611985, JString, required = false,
                                 default = nil)
  if valid_611985 != nil:
    section.add "maxitems", valid_611985
  var valid_611986 = query.getOrDefault("StartRecordName")
  valid_611986 = validateParameter(valid_611986, JString, required = false,
                                 default = nil)
  if valid_611986 != nil:
    section.add "StartRecordName", valid_611986
  var valid_611987 = query.getOrDefault("StartRecordIdentifier")
  valid_611987 = validateParameter(valid_611987, JString, required = false,
                                 default = nil)
  if valid_611987 != nil:
    section.add "StartRecordIdentifier", valid_611987
  var valid_611988 = query.getOrDefault("StartRecordType")
  valid_611988 = validateParameter(valid_611988, JString, required = false,
                                 default = nil)
  if valid_611988 != nil:
    section.add "StartRecordType", valid_611988
  var valid_611989 = query.getOrDefault("identifier")
  valid_611989 = validateParameter(valid_611989, JString, required = false,
                                 default = nil)
  if valid_611989 != nil:
    section.add "identifier", valid_611989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611990 = header.getOrDefault("X-Amz-Signature")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Signature", valid_611990
  var valid_611991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "X-Amz-Content-Sha256", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-Date")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Date", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-Credential")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-Credential", valid_611993
  var valid_611994 = header.getOrDefault("X-Amz-Security-Token")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "X-Amz-Security-Token", valid_611994
  var valid_611995 = header.getOrDefault("X-Amz-Algorithm")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "X-Amz-Algorithm", valid_611995
  var valid_611996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611996 = validateParameter(valid_611996, JString, required = false,
                                 default = nil)
  if valid_611996 != nil:
    section.add "X-Amz-SignedHeaders", valid_611996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611997: Call_ListResourceRecordSets_611978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ## 
  let valid = call_611997.validator(path, query, header, formData, body)
  let scheme = call_611997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611997.url(scheme.get, call_611997.host, call_611997.base,
                         call_611997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611997, url, valid)

proc call*(call_611998: Call_ListResourceRecordSets_611978; Id: string;
          name: string = ""; MaxItems: string = ""; `type`: string = "SOA";
          maxitems: string = ""; StartRecordName: string = "";
          StartRecordIdentifier: string = ""; StartRecordType: string = "";
          identifier: string = ""): Recallable =
  ## listResourceRecordSets
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ##   name: string
  ##       : The first name in the lexicographic ordering of resource record sets that you want to list.
  ##   MaxItems: string
  ##           : Pagination limit
  ##   type: string
  ##       : <p>The type of resource record set to begin the record listing from.</p> <p>Valid values for basic resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>NS</code> | <code>PTR</code> | <code>SOA</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for weighted, latency, geolocation, and failover resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>PTR</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for alias resource record sets: </p> <ul> <li> <p> <b>API Gateway custom regional API or edge-optimized API</b>: A</p> </li> <li> <p> <b>CloudFront distribution</b>: A or AAAA</p> </li> <li> <p> <b>Elastic Beanstalk environment that has a regionalized subdomain</b>: A</p> </li> <li> <p> <b>Elastic Load Balancing load balancer</b>: A | AAAA</p> </li> <li> <p> <b>Amazon S3 bucket</b>: A</p> </li> <li> <p> <b>Amazon VPC interface VPC endpoint</b>: A</p> </li> <li> <p> <b>Another resource record set in this hosted zone:</b> The type of the resource record set that the alias references.</p> </li> </ul> <p>Constraint: Specifying <code>type</code> without specifying <code>name</code> returns an <code>InvalidInput</code> error.</p>
  ##   maxitems: string
  ##           : (Optional) The maximum number of resource records sets to include in the response body for this request. If the response includes more than <code>maxitems</code> resource record sets, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of the <code>NextRecordName</code> and <code>NextRecordType</code> elements in the response identify the first resource record set in the next group of <code>maxitems</code> resource record sets.
  ##   StartRecordName: string
  ##                  : Pagination token
  ##   StartRecordIdentifier: string
  ##                        : Pagination token
  ##   StartRecordType: string
  ##                  : Pagination token
  ##   Id: string (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to list.
  ##   identifier: string
  ##             :  <i>Resource record sets that have a routing policy other than simple:</i> If results were truncated for a given DNS name and type, specify the value of <code>NextRecordIdentifier</code> from the previous response to get the next resource record set that has the current DNS name and type.
  var path_611999 = newJObject()
  var query_612000 = newJObject()
  add(query_612000, "name", newJString(name))
  add(query_612000, "MaxItems", newJString(MaxItems))
  add(query_612000, "type", newJString(`type`))
  add(query_612000, "maxitems", newJString(maxitems))
  add(query_612000, "StartRecordName", newJString(StartRecordName))
  add(query_612000, "StartRecordIdentifier", newJString(StartRecordIdentifier))
  add(query_612000, "StartRecordType", newJString(StartRecordType))
  add(path_611999, "Id", newJString(Id))
  add(query_612000, "identifier", newJString(identifier))
  result = call_611998.call(path_611999, query_612000, nil, nil, nil)

var listResourceRecordSets* = Call_ListResourceRecordSets_611978(
    name: "listResourceRecordSets", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}/rrset",
    validator: validate_ListResourceRecordSets_611979, base: "/",
    url: url_ListResourceRecordSets_611980, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResources_612001 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResources_612003(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceType" in path, "`ResourceType` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/tags/"),
               (kind: VariableSegment, value: "ResourceType")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResources_612002(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resources.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  section = newJObject()
  var valid_612004 = path.getOrDefault("ResourceType")
  valid_612004 = validateParameter(valid_612004, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_612004 != nil:
    section.add "ResourceType", valid_612004
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612005 = header.getOrDefault("X-Amz-Signature")
  valid_612005 = validateParameter(valid_612005, JString, required = false,
                                 default = nil)
  if valid_612005 != nil:
    section.add "X-Amz-Signature", valid_612005
  var valid_612006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "X-Amz-Content-Sha256", valid_612006
  var valid_612007 = header.getOrDefault("X-Amz-Date")
  valid_612007 = validateParameter(valid_612007, JString, required = false,
                                 default = nil)
  if valid_612007 != nil:
    section.add "X-Amz-Date", valid_612007
  var valid_612008 = header.getOrDefault("X-Amz-Credential")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "X-Amz-Credential", valid_612008
  var valid_612009 = header.getOrDefault("X-Amz-Security-Token")
  valid_612009 = validateParameter(valid_612009, JString, required = false,
                                 default = nil)
  if valid_612009 != nil:
    section.add "X-Amz-Security-Token", valid_612009
  var valid_612010 = header.getOrDefault("X-Amz-Algorithm")
  valid_612010 = validateParameter(valid_612010, JString, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "X-Amz-Algorithm", valid_612010
  var valid_612011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "X-Amz-SignedHeaders", valid_612011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612013: Call_ListTagsForResources_612001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_612013.validator(path, query, header, formData, body)
  let scheme = call_612013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612013.url(scheme.get, call_612013.host, call_612013.base,
                         call_612013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612013, url, valid)

proc call*(call_612014: Call_ListTagsForResources_612001; body: JsonNode;
          ResourceType: string = "healthcheck"): Recallable =
  ## listTagsForResources
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceType: string (required)
  ##               : <p>The type of the resources.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   body: JObject (required)
  var path_612015 = newJObject()
  var body_612016 = newJObject()
  add(path_612015, "ResourceType", newJString(ResourceType))
  if body != nil:
    body_612016 = body
  result = call_612014.call(path_612015, nil, nil, nil, body_612016)

var listTagsForResources* = Call_ListTagsForResources_612001(
    name: "listTagsForResources", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/tags/{ResourceType}",
    validator: validate_ListTagsForResources_612002, base: "/",
    url: url_ListTagsForResources_612003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicies_612017 = ref object of OpenApiRestCall_610658
proc url_ListTrafficPolicies_612019(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrafficPolicies_612018(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxitems: JString
  ##           : (Optional) The maximum number of traffic policies that you want Amazon Route 53 to return in response to this request. If you have more than <code>MaxItems</code> traffic policies, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>TrafficPolicyIdMarker</code> is the ID of the first traffic policy that Route 53 will return if you submit another request.
  ##   trafficpolicyid: JString
  ##                  : <p>(Conditional) For your first request to <code>ListTrafficPolicies</code>, don't include the <code>TrafficPolicyIdMarker</code> parameter.</p> <p>If you have more traffic policies than the value of <code>MaxItems</code>, <code>ListTrafficPolicies</code> returns only the first <code>MaxItems</code> traffic policies. To get the next group of policies, submit another request to <code>ListTrafficPolicies</code>. For the value of <code>TrafficPolicyIdMarker</code>, specify the value of <code>TrafficPolicyIdMarker</code> that was returned in the previous response.</p>
  section = newJObject()
  var valid_612020 = query.getOrDefault("maxitems")
  valid_612020 = validateParameter(valid_612020, JString, required = false,
                                 default = nil)
  if valid_612020 != nil:
    section.add "maxitems", valid_612020
  var valid_612021 = query.getOrDefault("trafficpolicyid")
  valid_612021 = validateParameter(valid_612021, JString, required = false,
                                 default = nil)
  if valid_612021 != nil:
    section.add "trafficpolicyid", valid_612021
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612022 = header.getOrDefault("X-Amz-Signature")
  valid_612022 = validateParameter(valid_612022, JString, required = false,
                                 default = nil)
  if valid_612022 != nil:
    section.add "X-Amz-Signature", valid_612022
  var valid_612023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "X-Amz-Content-Sha256", valid_612023
  var valid_612024 = header.getOrDefault("X-Amz-Date")
  valid_612024 = validateParameter(valid_612024, JString, required = false,
                                 default = nil)
  if valid_612024 != nil:
    section.add "X-Amz-Date", valid_612024
  var valid_612025 = header.getOrDefault("X-Amz-Credential")
  valid_612025 = validateParameter(valid_612025, JString, required = false,
                                 default = nil)
  if valid_612025 != nil:
    section.add "X-Amz-Credential", valid_612025
  var valid_612026 = header.getOrDefault("X-Amz-Security-Token")
  valid_612026 = validateParameter(valid_612026, JString, required = false,
                                 default = nil)
  if valid_612026 != nil:
    section.add "X-Amz-Security-Token", valid_612026
  var valid_612027 = header.getOrDefault("X-Amz-Algorithm")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "X-Amz-Algorithm", valid_612027
  var valid_612028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-SignedHeaders", valid_612028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612029: Call_ListTrafficPolicies_612017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ## 
  let valid = call_612029.validator(path, query, header, formData, body)
  let scheme = call_612029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612029.url(scheme.get, call_612029.host, call_612029.base,
                         call_612029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612029, url, valid)

proc call*(call_612030: Call_ListTrafficPolicies_612017; maxitems: string = "";
          trafficpolicyid: string = ""): Recallable =
  ## listTrafficPolicies
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ##   maxitems: string
  ##           : (Optional) The maximum number of traffic policies that you want Amazon Route 53 to return in response to this request. If you have more than <code>MaxItems</code> traffic policies, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>TrafficPolicyIdMarker</code> is the ID of the first traffic policy that Route 53 will return if you submit another request.
  ##   trafficpolicyid: string
  ##                  : <p>(Conditional) For your first request to <code>ListTrafficPolicies</code>, don't include the <code>TrafficPolicyIdMarker</code> parameter.</p> <p>If you have more traffic policies than the value of <code>MaxItems</code>, <code>ListTrafficPolicies</code> returns only the first <code>MaxItems</code> traffic policies. To get the next group of policies, submit another request to <code>ListTrafficPolicies</code>. For the value of <code>TrafficPolicyIdMarker</code>, specify the value of <code>TrafficPolicyIdMarker</code> that was returned in the previous response.</p>
  var query_612031 = newJObject()
  add(query_612031, "maxitems", newJString(maxitems))
  add(query_612031, "trafficpolicyid", newJString(trafficpolicyid))
  result = call_612030.call(nil, query_612031, nil, nil, nil)

var listTrafficPolicies* = Call_ListTrafficPolicies_612017(
    name: "listTrafficPolicies", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicies",
    validator: validate_ListTrafficPolicies_612018, base: "/",
    url: url_ListTrafficPolicies_612019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstances_612032 = ref object of OpenApiRestCall_610658
proc url_ListTrafficPolicyInstances_612034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrafficPolicyInstances_612033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances that you want Amazon Route 53 to return in response to a <code>ListTrafficPolicyInstances</code> request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance in the next group of <code>MaxItems</code> traffic policy instances.
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: JString
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>HostedZoneId</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  var valid_612035 = query.getOrDefault("trafficpolicyinstancetype")
  valid_612035 = validateParameter(valid_612035, JString, required = false,
                                 default = newJString("SOA"))
  if valid_612035 != nil:
    section.add "trafficpolicyinstancetype", valid_612035
  var valid_612036 = query.getOrDefault("maxitems")
  valid_612036 = validateParameter(valid_612036, JString, required = false,
                                 default = nil)
  if valid_612036 != nil:
    section.add "maxitems", valid_612036
  var valid_612037 = query.getOrDefault("trafficpolicyinstancename")
  valid_612037 = validateParameter(valid_612037, JString, required = false,
                                 default = nil)
  if valid_612037 != nil:
    section.add "trafficpolicyinstancename", valid_612037
  var valid_612038 = query.getOrDefault("hostedzoneid")
  valid_612038 = validateParameter(valid_612038, JString, required = false,
                                 default = nil)
  if valid_612038 != nil:
    section.add "hostedzoneid", valid_612038
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612039 = header.getOrDefault("X-Amz-Signature")
  valid_612039 = validateParameter(valid_612039, JString, required = false,
                                 default = nil)
  if valid_612039 != nil:
    section.add "X-Amz-Signature", valid_612039
  var valid_612040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "X-Amz-Content-Sha256", valid_612040
  var valid_612041 = header.getOrDefault("X-Amz-Date")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "X-Amz-Date", valid_612041
  var valid_612042 = header.getOrDefault("X-Amz-Credential")
  valid_612042 = validateParameter(valid_612042, JString, required = false,
                                 default = nil)
  if valid_612042 != nil:
    section.add "X-Amz-Credential", valid_612042
  var valid_612043 = header.getOrDefault("X-Amz-Security-Token")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "X-Amz-Security-Token", valid_612043
  var valid_612044 = header.getOrDefault("X-Amz-Algorithm")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-Algorithm", valid_612044
  var valid_612045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612045 = validateParameter(valid_612045, JString, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "X-Amz-SignedHeaders", valid_612045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612046: Call_ListTrafficPolicyInstances_612032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_612046.validator(path, query, header, formData, body)
  let scheme = call_612046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612046.url(scheme.get, call_612046.host, call_612046.base,
                         call_612046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612046, url, valid)

proc call*(call_612047: Call_ListTrafficPolicyInstances_612032;
          trafficpolicyinstancetype: string = "SOA"; maxitems: string = "";
          trafficpolicyinstancename: string = ""; hostedzoneid: string = ""): Recallable =
  ## listTrafficPolicyInstances
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances that you want Amazon Route 53 to return in response to a <code>ListTrafficPolicyInstances</code> request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance in the next group of <code>MaxItems</code> traffic policy instances.
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: string
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>HostedZoneId</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_612048 = newJObject()
  add(query_612048, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  add(query_612048, "maxitems", newJString(maxitems))
  add(query_612048, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  add(query_612048, "hostedzoneid", newJString(hostedzoneid))
  result = call_612047.call(nil, query_612048, nil, nil, nil)

var listTrafficPolicyInstances* = Call_ListTrafficPolicyInstances_612032(
    name: "listTrafficPolicyInstances", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicyinstances",
    validator: validate_ListTrafficPolicyInstances_612033, base: "/",
    url: url_ListTrafficPolicyInstances_612034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstancesByHostedZone_612049 = ref object of OpenApiRestCall_610658
proc url_ListTrafficPolicyInstancesByHostedZone_612051(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrafficPolicyInstancesByHostedZone_612050(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   id: JString (required)
  ##     : The ID of the hosted zone that you want to list traffic policy instances for.
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  var valid_612052 = query.getOrDefault("trafficpolicyinstancetype")
  valid_612052 = validateParameter(valid_612052, JString, required = false,
                                 default = newJString("SOA"))
  if valid_612052 != nil:
    section.add "trafficpolicyinstancetype", valid_612052
  var valid_612053 = query.getOrDefault("maxitems")
  valid_612053 = validateParameter(valid_612053, JString, required = false,
                                 default = nil)
  if valid_612053 != nil:
    section.add "maxitems", valid_612053
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_612054 = query.getOrDefault("id")
  valid_612054 = validateParameter(valid_612054, JString, required = true,
                                 default = nil)
  if valid_612054 != nil:
    section.add "id", valid_612054
  var valid_612055 = query.getOrDefault("trafficpolicyinstancename")
  valid_612055 = validateParameter(valid_612055, JString, required = false,
                                 default = nil)
  if valid_612055 != nil:
    section.add "trafficpolicyinstancename", valid_612055
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612056 = header.getOrDefault("X-Amz-Signature")
  valid_612056 = validateParameter(valid_612056, JString, required = false,
                                 default = nil)
  if valid_612056 != nil:
    section.add "X-Amz-Signature", valid_612056
  var valid_612057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612057 = validateParameter(valid_612057, JString, required = false,
                                 default = nil)
  if valid_612057 != nil:
    section.add "X-Amz-Content-Sha256", valid_612057
  var valid_612058 = header.getOrDefault("X-Amz-Date")
  valid_612058 = validateParameter(valid_612058, JString, required = false,
                                 default = nil)
  if valid_612058 != nil:
    section.add "X-Amz-Date", valid_612058
  var valid_612059 = header.getOrDefault("X-Amz-Credential")
  valid_612059 = validateParameter(valid_612059, JString, required = false,
                                 default = nil)
  if valid_612059 != nil:
    section.add "X-Amz-Credential", valid_612059
  var valid_612060 = header.getOrDefault("X-Amz-Security-Token")
  valid_612060 = validateParameter(valid_612060, JString, required = false,
                                 default = nil)
  if valid_612060 != nil:
    section.add "X-Amz-Security-Token", valid_612060
  var valid_612061 = header.getOrDefault("X-Amz-Algorithm")
  valid_612061 = validateParameter(valid_612061, JString, required = false,
                                 default = nil)
  if valid_612061 != nil:
    section.add "X-Amz-Algorithm", valid_612061
  var valid_612062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612062 = validateParameter(valid_612062, JString, required = false,
                                 default = nil)
  if valid_612062 != nil:
    section.add "X-Amz-SignedHeaders", valid_612062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612063: Call_ListTrafficPolicyInstancesByHostedZone_612049;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_612063.validator(path, query, header, formData, body)
  let scheme = call_612063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612063.url(scheme.get, call_612063.host, call_612063.base,
                         call_612063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612063, url, valid)

proc call*(call_612064: Call_ListTrafficPolicyInstancesByHostedZone_612049;
          id: string; trafficpolicyinstancetype: string = "SOA";
          maxitems: string = ""; trafficpolicyinstancename: string = ""): Recallable =
  ## listTrafficPolicyInstancesByHostedZone
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   id: string (required)
  ##     : The ID of the hosted zone that you want to list traffic policy instances for.
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_612065 = newJObject()
  add(query_612065, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  add(query_612065, "maxitems", newJString(maxitems))
  add(query_612065, "id", newJString(id))
  add(query_612065, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  result = call_612064.call(nil, query_612065, nil, nil, nil)

var listTrafficPolicyInstancesByHostedZone* = Call_ListTrafficPolicyInstancesByHostedZone_612049(
    name: "listTrafficPolicyInstancesByHostedZone", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstances/hostedzone#id",
    validator: validate_ListTrafficPolicyInstancesByHostedZone_612050, base: "/",
    url: url_ListTrafficPolicyInstancesByHostedZone_612051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstancesByPolicy_612066 = ref object of OpenApiRestCall_610658
proc url_ListTrafficPolicyInstancesByPolicy_612068(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrafficPolicyInstancesByPolicy_612067(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   version: JInt (required)
  ##          : The version of the traffic policy for which you want to list traffic policy instances. The version must be associated with the traffic policy that is specified by <code>TrafficPolicyId</code>.
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   id: JString (required)
  ##     : The ID of the traffic policy for which you want to list traffic policy instances.
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: JString
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request. </p> <p>For the value of <code>hostedzoneid</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  var valid_612069 = query.getOrDefault("trafficpolicyinstancetype")
  valid_612069 = validateParameter(valid_612069, JString, required = false,
                                 default = newJString("SOA"))
  if valid_612069 != nil:
    section.add "trafficpolicyinstancetype", valid_612069
  assert query != nil, "query argument is necessary due to required `version` field"
  var valid_612070 = query.getOrDefault("version")
  valid_612070 = validateParameter(valid_612070, JInt, required = true, default = nil)
  if valid_612070 != nil:
    section.add "version", valid_612070
  var valid_612071 = query.getOrDefault("maxitems")
  valid_612071 = validateParameter(valid_612071, JString, required = false,
                                 default = nil)
  if valid_612071 != nil:
    section.add "maxitems", valid_612071
  var valid_612072 = query.getOrDefault("id")
  valid_612072 = validateParameter(valid_612072, JString, required = true,
                                 default = nil)
  if valid_612072 != nil:
    section.add "id", valid_612072
  var valid_612073 = query.getOrDefault("trafficpolicyinstancename")
  valid_612073 = validateParameter(valid_612073, JString, required = false,
                                 default = nil)
  if valid_612073 != nil:
    section.add "trafficpolicyinstancename", valid_612073
  var valid_612074 = query.getOrDefault("hostedzoneid")
  valid_612074 = validateParameter(valid_612074, JString, required = false,
                                 default = nil)
  if valid_612074 != nil:
    section.add "hostedzoneid", valid_612074
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612075 = header.getOrDefault("X-Amz-Signature")
  valid_612075 = validateParameter(valid_612075, JString, required = false,
                                 default = nil)
  if valid_612075 != nil:
    section.add "X-Amz-Signature", valid_612075
  var valid_612076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612076 = validateParameter(valid_612076, JString, required = false,
                                 default = nil)
  if valid_612076 != nil:
    section.add "X-Amz-Content-Sha256", valid_612076
  var valid_612077 = header.getOrDefault("X-Amz-Date")
  valid_612077 = validateParameter(valid_612077, JString, required = false,
                                 default = nil)
  if valid_612077 != nil:
    section.add "X-Amz-Date", valid_612077
  var valid_612078 = header.getOrDefault("X-Amz-Credential")
  valid_612078 = validateParameter(valid_612078, JString, required = false,
                                 default = nil)
  if valid_612078 != nil:
    section.add "X-Amz-Credential", valid_612078
  var valid_612079 = header.getOrDefault("X-Amz-Security-Token")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "X-Amz-Security-Token", valid_612079
  var valid_612080 = header.getOrDefault("X-Amz-Algorithm")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "X-Amz-Algorithm", valid_612080
  var valid_612081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612081 = validateParameter(valid_612081, JString, required = false,
                                 default = nil)
  if valid_612081 != nil:
    section.add "X-Amz-SignedHeaders", valid_612081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612082: Call_ListTrafficPolicyInstancesByPolicy_612066;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_612082.validator(path, query, header, formData, body)
  let scheme = call_612082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612082.url(scheme.get, call_612082.host, call_612082.base,
                         call_612082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612082, url, valid)

proc call*(call_612083: Call_ListTrafficPolicyInstancesByPolicy_612066;
          version: int; id: string; trafficpolicyinstancetype: string = "SOA";
          maxitems: string = ""; trafficpolicyinstancename: string = "";
          hostedzoneid: string = ""): Recallable =
  ## listTrafficPolicyInstancesByPolicy
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   version: int (required)
  ##          : The version of the traffic policy for which you want to list traffic policy instances. The version must be associated with the traffic policy that is specified by <code>TrafficPolicyId</code>.
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   id: string (required)
  ##     : The ID of the traffic policy for which you want to list traffic policy instances.
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: string
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request. </p> <p>For the value of <code>hostedzoneid</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_612084 = newJObject()
  add(query_612084, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  add(query_612084, "version", newJInt(version))
  add(query_612084, "maxitems", newJString(maxitems))
  add(query_612084, "id", newJString(id))
  add(query_612084, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  add(query_612084, "hostedzoneid", newJString(hostedzoneid))
  result = call_612083.call(nil, query_612084, nil, nil, nil)

var listTrafficPolicyInstancesByPolicy* = Call_ListTrafficPolicyInstancesByPolicy_612066(
    name: "listTrafficPolicyInstancesByPolicy", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstances/trafficpolicy#id&version",
    validator: validate_ListTrafficPolicyInstancesByPolicy_612067, base: "/",
    url: url_ListTrafficPolicyInstancesByPolicy_612068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyVersions_612085 = ref object of OpenApiRestCall_610658
proc url_ListTrafficPolicyVersions_612087(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicies/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTrafficPolicyVersions_612086(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Specify the value of <code>Id</code> of the traffic policy for which you want to list all versions.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_612088 = path.getOrDefault("Id")
  valid_612088 = validateParameter(valid_612088, JString, required = true,
                                 default = nil)
  if valid_612088 != nil:
    section.add "Id", valid_612088
  result.add "path", section
  ## parameters in `query` object:
  ##   maxitems: JString
  ##           : The maximum number of traffic policy versions that you want Amazon Route 53 to include in the response body for this request. If the specified traffic policy has more than <code>MaxItems</code> versions, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of the <code>TrafficPolicyVersionMarker</code> element is the ID of the first version that Route 53 will return if you submit another request.
  ##   trafficpolicyversion: JString
  ##                       : <p>For your first request to <code>ListTrafficPolicyVersions</code>, don't include the <code>TrafficPolicyVersionMarker</code> parameter.</p> <p>If you have more traffic policy versions than the value of <code>MaxItems</code>, <code>ListTrafficPolicyVersions</code> returns only the first group of <code>MaxItems</code> versions. To get more traffic policy versions, submit another <code>ListTrafficPolicyVersions</code> request. For the value of <code>TrafficPolicyVersionMarker</code>, specify the value of <code>TrafficPolicyVersionMarker</code> in the previous response.</p>
  section = newJObject()
  var valid_612089 = query.getOrDefault("maxitems")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "maxitems", valid_612089
  var valid_612090 = query.getOrDefault("trafficpolicyversion")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "trafficpolicyversion", valid_612090
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612091 = header.getOrDefault("X-Amz-Signature")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Signature", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-Content-Sha256", valid_612092
  var valid_612093 = header.getOrDefault("X-Amz-Date")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-Date", valid_612093
  var valid_612094 = header.getOrDefault("X-Amz-Credential")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "X-Amz-Credential", valid_612094
  var valid_612095 = header.getOrDefault("X-Amz-Security-Token")
  valid_612095 = validateParameter(valid_612095, JString, required = false,
                                 default = nil)
  if valid_612095 != nil:
    section.add "X-Amz-Security-Token", valid_612095
  var valid_612096 = header.getOrDefault("X-Amz-Algorithm")
  valid_612096 = validateParameter(valid_612096, JString, required = false,
                                 default = nil)
  if valid_612096 != nil:
    section.add "X-Amz-Algorithm", valid_612096
  var valid_612097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612097 = validateParameter(valid_612097, JString, required = false,
                                 default = nil)
  if valid_612097 != nil:
    section.add "X-Amz-SignedHeaders", valid_612097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612098: Call_ListTrafficPolicyVersions_612085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ## 
  let valid = call_612098.validator(path, query, header, formData, body)
  let scheme = call_612098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612098.url(scheme.get, call_612098.host, call_612098.base,
                         call_612098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612098, url, valid)

proc call*(call_612099: Call_ListTrafficPolicyVersions_612085; Id: string;
          maxitems: string = ""; trafficpolicyversion: string = ""): Recallable =
  ## listTrafficPolicyVersions
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy versions that you want Amazon Route 53 to include in the response body for this request. If the specified traffic policy has more than <code>MaxItems</code> versions, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of the <code>TrafficPolicyVersionMarker</code> element is the ID of the first version that Route 53 will return if you submit another request.
  ##   trafficpolicyversion: string
  ##                       : <p>For your first request to <code>ListTrafficPolicyVersions</code>, don't include the <code>TrafficPolicyVersionMarker</code> parameter.</p> <p>If you have more traffic policy versions than the value of <code>MaxItems</code>, <code>ListTrafficPolicyVersions</code> returns only the first group of <code>MaxItems</code> versions. To get more traffic policy versions, submit another <code>ListTrafficPolicyVersions</code> request. For the value of <code>TrafficPolicyVersionMarker</code>, specify the value of <code>TrafficPolicyVersionMarker</code> in the previous response.</p>
  ##   Id: string (required)
  ##     : Specify the value of <code>Id</code> of the traffic policy for which you want to list all versions.
  var path_612100 = newJObject()
  var query_612101 = newJObject()
  add(query_612101, "maxitems", newJString(maxitems))
  add(query_612101, "trafficpolicyversion", newJString(trafficpolicyversion))
  add(path_612100, "Id", newJString(Id))
  result = call_612099.call(path_612100, query_612101, nil, nil, nil)

var listTrafficPolicyVersions* = Call_ListTrafficPolicyVersions_612085(
    name: "listTrafficPolicyVersions", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicies/{Id}/versions",
    validator: validate_ListTrafficPolicyVersions_612086, base: "/",
    url: url_ListTrafficPolicyVersions_612087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestDNSAnswer_612102 = ref object of OpenApiRestCall_610658
proc url_TestDNSAnswer_612104(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TestDNSAnswer_612103(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   edns0clientsubnetip: JString
  ##                      : If the resolver that you specified for resolverip supports EDNS0, specify the IPv4 or IPv6 address of a client in the applicable location, for example, <code>192.0.2.44</code> or <code>2001:db8:85a3::8a2e:370:7334</code>.
  ##   edns0clientsubnetmask: JString
  ##                        : <p>If you specify an IP address for <code>edns0clientsubnetip</code>, you can optionally specify the number of bits of the IP address that you want the checking tool to include in the DNS query. For example, if you specify <code>192.0.2.44</code> for <code>edns0clientsubnetip</code> and <code>24</code> for <code>edns0clientsubnetmask</code>, the checking tool will simulate a request from 192.0.2.0/24. The default value is 24 bits for IPv4 addresses and 64 bits for IPv6 addresses.</p> <p>The range of valid values depends on whether <code>edns0clientsubnetip</code> is an IPv4 or an IPv6 address:</p> <ul> <li> <p> <b>IPv4</b>: Specify a value between 0 and 32</p> </li> <li> <p> <b>IPv6</b>: Specify a value between 0 and 128</p> </li> </ul>
  ##   recordname: JString (required)
  ##             : The name of the resource record set that you want Amazon Route 53 to simulate a query for.
  ##   resolverip: JString
  ##             : If you want to simulate a request from a specific DNS resolver, specify the IP address for that resolver. If you omit this value, <code>TestDnsAnswer</code> uses the IP address of a DNS resolver in the AWS US East (N. Virginia) Region (<code>us-east-1</code>).
  ##   recordtype: JString (required)
  ##             : The type of the resource record set.
  ##   hostedzoneid: JString (required)
  ##               : The ID of the hosted zone that you want Amazon Route 53 to simulate a query for.
  section = newJObject()
  var valid_612105 = query.getOrDefault("edns0clientsubnetip")
  valid_612105 = validateParameter(valid_612105, JString, required = false,
                                 default = nil)
  if valid_612105 != nil:
    section.add "edns0clientsubnetip", valid_612105
  var valid_612106 = query.getOrDefault("edns0clientsubnetmask")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "edns0clientsubnetmask", valid_612106
  assert query != nil,
        "query argument is necessary due to required `recordname` field"
  var valid_612107 = query.getOrDefault("recordname")
  valid_612107 = validateParameter(valid_612107, JString, required = true,
                                 default = nil)
  if valid_612107 != nil:
    section.add "recordname", valid_612107
  var valid_612108 = query.getOrDefault("resolverip")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "resolverip", valid_612108
  var valid_612109 = query.getOrDefault("recordtype")
  valid_612109 = validateParameter(valid_612109, JString, required = true,
                                 default = newJString("SOA"))
  if valid_612109 != nil:
    section.add "recordtype", valid_612109
  var valid_612110 = query.getOrDefault("hostedzoneid")
  valid_612110 = validateParameter(valid_612110, JString, required = true,
                                 default = nil)
  if valid_612110 != nil:
    section.add "hostedzoneid", valid_612110
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612111 = header.getOrDefault("X-Amz-Signature")
  valid_612111 = validateParameter(valid_612111, JString, required = false,
                                 default = nil)
  if valid_612111 != nil:
    section.add "X-Amz-Signature", valid_612111
  var valid_612112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612112 = validateParameter(valid_612112, JString, required = false,
                                 default = nil)
  if valid_612112 != nil:
    section.add "X-Amz-Content-Sha256", valid_612112
  var valid_612113 = header.getOrDefault("X-Amz-Date")
  valid_612113 = validateParameter(valid_612113, JString, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "X-Amz-Date", valid_612113
  var valid_612114 = header.getOrDefault("X-Amz-Credential")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = nil)
  if valid_612114 != nil:
    section.add "X-Amz-Credential", valid_612114
  var valid_612115 = header.getOrDefault("X-Amz-Security-Token")
  valid_612115 = validateParameter(valid_612115, JString, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "X-Amz-Security-Token", valid_612115
  var valid_612116 = header.getOrDefault("X-Amz-Algorithm")
  valid_612116 = validateParameter(valid_612116, JString, required = false,
                                 default = nil)
  if valid_612116 != nil:
    section.add "X-Amz-Algorithm", valid_612116
  var valid_612117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612117 = validateParameter(valid_612117, JString, required = false,
                                 default = nil)
  if valid_612117 != nil:
    section.add "X-Amz-SignedHeaders", valid_612117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612118: Call_TestDNSAnswer_612102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ## 
  let valid = call_612118.validator(path, query, header, formData, body)
  let scheme = call_612118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612118.url(scheme.get, call_612118.host, call_612118.base,
                         call_612118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612118, url, valid)

proc call*(call_612119: Call_TestDNSAnswer_612102; recordname: string;
          hostedzoneid: string; edns0clientsubnetip: string = "";
          edns0clientsubnetmask: string = ""; resolverip: string = "";
          recordtype: string = "SOA"): Recallable =
  ## testDNSAnswer
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ##   edns0clientsubnetip: string
  ##                      : If the resolver that you specified for resolverip supports EDNS0, specify the IPv4 or IPv6 address of a client in the applicable location, for example, <code>192.0.2.44</code> or <code>2001:db8:85a3::8a2e:370:7334</code>.
  ##   edns0clientsubnetmask: string
  ##                        : <p>If you specify an IP address for <code>edns0clientsubnetip</code>, you can optionally specify the number of bits of the IP address that you want the checking tool to include in the DNS query. For example, if you specify <code>192.0.2.44</code> for <code>edns0clientsubnetip</code> and <code>24</code> for <code>edns0clientsubnetmask</code>, the checking tool will simulate a request from 192.0.2.0/24. The default value is 24 bits for IPv4 addresses and 64 bits for IPv6 addresses.</p> <p>The range of valid values depends on whether <code>edns0clientsubnetip</code> is an IPv4 or an IPv6 address:</p> <ul> <li> <p> <b>IPv4</b>: Specify a value between 0 and 32</p> </li> <li> <p> <b>IPv6</b>: Specify a value between 0 and 128</p> </li> </ul>
  ##   recordname: string (required)
  ##             : The name of the resource record set that you want Amazon Route 53 to simulate a query for.
  ##   resolverip: string
  ##             : If you want to simulate a request from a specific DNS resolver, specify the IP address for that resolver. If you omit this value, <code>TestDnsAnswer</code> uses the IP address of a DNS resolver in the AWS US East (N. Virginia) Region (<code>us-east-1</code>).
  ##   recordtype: string (required)
  ##             : The type of the resource record set.
  ##   hostedzoneid: string (required)
  ##               : The ID of the hosted zone that you want Amazon Route 53 to simulate a query for.
  var query_612120 = newJObject()
  add(query_612120, "edns0clientsubnetip", newJString(edns0clientsubnetip))
  add(query_612120, "edns0clientsubnetmask", newJString(edns0clientsubnetmask))
  add(query_612120, "recordname", newJString(recordname))
  add(query_612120, "resolverip", newJString(resolverip))
  add(query_612120, "recordtype", newJString(recordtype))
  add(query_612120, "hostedzoneid", newJString(hostedzoneid))
  result = call_612119.call(nil, query_612120, nil, nil, nil)

var testDNSAnswer* = Call_TestDNSAnswer_612102(name: "testDNSAnswer",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/testdnsanswer#hostedzoneid&recordname&recordtype",
    validator: validate_TestDNSAnswer_612103, base: "/", url: url_TestDNSAnswer_612104,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
